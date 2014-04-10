package main

import  (
  "compress/gzip"
  "fmt"
  "flag"
  "math"
  "bytes"
	"encoding/binary"
  "io"
  "os"
  "encoding/json"
  "io/ioutil"
  "database/sql"
  _ "github.com/go-sql-driver/mysql"
  "strconv"
  "strings"
  "net/http"
)

type gzipResponseWriter struct {
	io.Writer
	http.ResponseWriter
}
 
func (w gzipResponseWriter) Write(b []byte) (int, error) {
	return w.Writer.Write(b)
}
 
func makeGzipHandler(fn http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !strings.Contains(r.Header.Get("Accept-Encoding"), "gzip") {
			fn(w, r)
			return
		}
		w.Header().Set("Content-Encoding", "gzip")
		gz := gzip.NewWriter(w)
		defer gz.Close()
		gzr := gzipResponseWriter{Writer: gz, ResponseWriter: w}
		fn(gzr, r)
	}
}

type IntPackBuffer struct {
  Buffer uint8
  Bitset io.Writer
  BufferFilled uint8
  Width uint8
}

func (b *IntPackBuffer) Write (value uint16) {
  buffer_open := 8 - b.BufferFilled
  if (b.Width <= 8) {
    enc_val := uint8(value)
    if (buffer_open > b.Width){
      output_val := enc_val << (buffer_open - b.Width)
      b.Buffer = b.Buffer | output_val
      b.BufferFilled = b.BufferFilled + b.Width
    } else {
      output_val := (enc_val >> (b.Width - buffer_open))
      b.Buffer = b.Buffer | output_val
      binary.Write(b.Bitset, binary.BigEndian, b.Buffer)
      b.BufferFilled = b.Width - buffer_open
      b.Buffer = 0 | (enc_val << (8 - b.BufferFilled))
    }
  } else {
    //enc_val := uint16(v) 
  }
}

func (b *IntPackBuffer) Finalize () ([]byte) {
  buffer := (b.Bitset).(*bytes.Buffer)
  if (b.BufferFilled == 0){ return buffer.Bytes()}
  if (b.Width < 8){
    binary.Write(b.Bitset, binary.BigEndian, b.Buffer) 
  }
  return buffer.Bytes()
}

type TampegConfig struct {
  User string
  Password string
  Port int
  Database string
  Table string
  Query string
  IdField string `json:"id_field"`
  Attrs []*PackAttr
}

type PackAttr struct {
  Name string `json:"attr_name"`
  DisplayName string `json:"display_name"`
  MaxChoices uint32 `json:"max_choices"`
  Possibilities []string `json:"possibilities"`
  FilterType string `json:"filter_type"`
  DisplayType string `json:"display_type"`
  Encoding string `json:"encoding"`
  Bitset []byte `json:"pack"`
  BitWindowWidth uint32 `json:"bit_window_width"`
  ItemWindowWidth uint32 `json:"item_window_width"`
  MaxGuid uint32 `json:"max_guid"`
}

type Pack struct{
  BufferUrl string `json:"buffer_url"`
  DefaultThumbnail string `json:"default_thumbnail"`
  DefaultOneup string `json:"default_oneup"`
  Attrs []*PackAttr `json:"attributes"`
  Existence *PackAttr `json:"existence"`
}

type DBItem struct{
  Attrs map[string][]string
  Guid uint64
}

func (pack *Pack) Create(data []*DBItem) {

  for v := range pack.Attrs {
    attr := pack.Attrs[v]
    num_possible := float64(len(attr.Possibilities))
    if ( float64(attr.MaxChoices) * math.Log2(num_possible + 1) < num_possible ){
      attr.Encoding = "integer"
      PackIntegerData(attr,data)
    } else {
      attr.Encoding = "bitmap"
      PackBitmapData(attr,data)
    }
  }

  existence_pack := PackExistence(data)
  pack.Existence = existence_pack

}

func SetBit(bitset []byte, offset uint64) {
  byte_offset := offset / 8
  bit_offset := 7 - (offset % 8)
  bitset[byte_offset] = bitset[byte_offset] | (1 << bit_offset)
}

func DumpBitmapBuffer(buffer []byte, bitset io.Writer, offset uint64) {
  current_buffer := buffer
  if (offset == 0 && current_buffer[0] == 0){
    return
  }
  binary.Write(bitset, binary.BigEndian, uint8(0))
  byte_length := (offset + 1) / 8
  bit_remainder := (offset + 1) % 8
  binary.Write(bitset, binary.BigEndian, uint32(byte_length))
  binary.Write(bitset, binary.BigEndian, uint8(bit_remainder))
  if(bit_remainder == 0){
    binary.Write(bitset, binary.BigEndian, current_buffer[0:byte_length])
  } else {
    binary.Write(bitset, binary.BigEndian, current_buffer[0:byte_length + 1])
  }
}

func WriteSkip(bitset io.Writer, skip uint32, last_guid uint64) (uint64) {
  binary.Write(bitset, binary.BigEndian, uint8(1))
  binary.Write(bitset, binary.BigEndian, skip)
  return last_guid + uint64(skip)
}

func WriteRun(bitset io.Writer, run uint32, last_guid uint64) (uint64) {
    binary.Write(bitset, binary.BigEndian, uint8(2))
    binary.Write(bitset, binary.BigEndian, run)
    return last_guid + uint64(run)
}

func WriteBitmap(bitset io.Writer, guids []uint64, bytes_needed int32, last_guid uint64, next_guid uint64) (uint64) {
    buffer := make([]byte,bytes_needed)
    final_guid := guids[len(guids) - 1]
    var padding uint64
    if next_guid > final_guid {
        padding = next_guid - final_guid - 1
    } else {
        padding = 0    
    }
    var buffer_offset uint64
    head := guids[0]
    if(last_guid == 0 || last_guid == head){
        buffer_offset = head - last_guid
    } else {
        buffer_offset = head - last_guid - 1
    }
    last_guid = head
    for _,guid := range(guids){
        buffer_offset = buffer_offset + (guid - last_guid)
        SetBit(buffer,buffer_offset)
        last_guid = guid
    }
    buffer_offset = buffer_offset + padding
    last_guid = last_guid + padding
    DumpBitmapBuffer(buffer,bitset,buffer_offset)
    return last_guid
}

type EncodingBlock struct{
    Guids []uint64
    EncodingType string
    Length uint32
    NextGuid uint64
}

func FlushRun(run *[]uint64,bitmap *[]uint64, encoding_set *[]EncodingBlock){
    run_length := uint32(len(*run))
    if(run_length > 40){
        FlushBitmap(bitmap,encoding_set,(*run)[0])
        *encoding_set = append(*encoding_set,EncodingBlock{EncodingType: "run",
                                                          Length: run_length})
    } else {
        *bitmap = append(*bitmap,*run...)
    }
    *run = (*run)[:0]
}

func FlushBitmap(bitmap *[]uint64, encoding_set *[]EncodingBlock, next_guid uint64){
    bitmap_length := uint32(len(*bitmap))
    if(bitmap_length > 0){
        bitmap_copy := make([]uint64,bitmap_length)
        copy(bitmap_copy,*bitmap)
        *encoding_set = append(*encoding_set,EncodingBlock{EncodingType: "bitmap",
                                                          Length: bitmap_length,
                                                          Guids: bitmap_copy,
                                                          NextGuid: next_guid,
                                                          })
    }
    *bitmap = (*bitmap)[:0]
}

func FlushSkip(length uint64, encoding_set *[]EncodingBlock){
    *encoding_set = append(*encoding_set,EncodingBlock{EncodingType: "skip",
                                                      Length: uint32(length),
                                                      })
}

func WriteEncodingSet(encoding_set []EncodingBlock,bytes_needed int32) (*bytes.Buffer){
    bitset := new(bytes.Buffer)
    last_guid := uint64(0)

    for _,block := range(encoding_set){
        switch block.EncodingType{
            case "bitmap":
                last_guid = WriteBitmap(bitset,block.Guids,bytes_needed,last_guid,block.NextGuid)
            case "run":
                last_guid = WriteRun(bitset,block.Length,last_guid)
            case "skip":
                last_guid = WriteSkip(bitset,block.Length,last_guid)
        }
    }   

    return bitset
}

func PackExistence(items []*DBItem) *PackAttr{
  num_items := len(items)
  final_guid := items[num_items- 1].Guid
  bytes_needed := int32(math.Ceil(float64(final_guid)/8))
  last_guid := uint64(0)
  run_guids := make([]uint64,0,num_items)
  bitmap_guids := make([]uint64,0,num_items)
  encoding_set := make([]EncodingBlock,0,50)
  diff_adj := uint64(0)

  for i := 0; i < num_items; i++ {
    current_item := (items)[i]
    guid := current_item.Guid
    if guid - last_guid <= 1 {
      
    } else if guid - last_guid <= 40 {
      FlushRun(&run_guids,&bitmap_guids,&encoding_set)
    } else {
      FlushRun(&run_guids,&bitmap_guids,&encoding_set)
      FlushBitmap(&bitmap_guids,&encoding_set,0)
      FlushSkip(guid - last_guid - diff_adj,&encoding_set)
    }
    run_guids = append(run_guids,guid)
    last_guid = guid
    diff_adj = 1
  }
  FlushRun(&run_guids,&bitmap_guids,&encoding_set)
  FlushBitmap(&bitmap_guids,&encoding_set,0)
  bitset := WriteEncodingSet(encoding_set,bytes_needed)
  return &PackAttr{Name: "existence", Bitset: bitset.Bytes(), Encoding: "existence"}
}

func PackIntegerData(attr *PackAttr,items []*DBItem) {
  num_items := uint32(len(items))
  num_possibilities := float64(len(attr.Possibilities) + 1)
  bit_window_width := uint32(math.Ceil(math.Log2(num_possibilities)))
  if(bit_window_width == 0) {
    bit_window_width = 1
  }
  item_window_width := bit_window_width * attr.MaxChoices
  bit_length := item_window_width * num_items
  byte_length := bit_length / 8
  bit_remainder := bit_length % 8 
  bitset := new(bytes.Buffer)
  buffer := new(IntPackBuffer)
  buffer.Bitset = bitset
  buffer.Width = uint8(bit_window_width)

  attr.ItemWindowWidth = item_window_width
  attr.BitWindowWidth = bit_window_width

  binary.Write(bitset, binary.BigEndian, uint32(byte_length))
  binary.Write(bitset, binary.BigEndian, uint8(bit_remainder))
  for _,item := range items {
    PackIntegerValues(buffer,attr,item)
  }
  attr.Bitset = buffer.Finalize()
}

func PackIntegerValues(buffer *IntPackBuffer,attr *PackAttr, item *DBItem) {
  attr_val := item.Attrs[attr.Name]
  LeftAlign := func(num_vals uint32){
    if(attr.MaxChoices <= num_vals){return}
    empty_vals := attr.MaxChoices - num_vals
    for i := uint32(0); i < empty_vals; i++ {
      buffer.Write(0)
    }
  }
  possibilities := attr.Possibilities
  for p := range(attr_val){
    current_val := attr_val[p]
    found_value := false
    for i := range (possibilities) {
      if(possibilities[i] == current_val && uint32(p) < attr.MaxChoices){
        buffer.Write(uint16(i+1))
        found_value = true
        break
      } else if (uint32(p) >= attr.MaxChoices){
        fmt.Println("Warning: Too Many Values",attr_val)
        break
      }
    }
    if (! found_value){
      buffer.Write(0)
    }
  }
  num_values := uint32(len(attr_val))
  LeftAlign(num_values)
}

func PackBitmapData(attr *PackAttr,items []*DBItem) {
  num_items := uint32(len(items))
  item_window_width := len(attr.Possibilities)
  bit_length := uint32(item_window_width) * num_items
  byte_length := bit_length / 8
  bit_remainder := bit_length % 8 
  bitset := new(bytes.Buffer)
  buffer := uint8(0)
  bi := 0

  attr.ItemWindowWidth = uint32(item_window_width)
  attr.BitWindowWidth = uint32(1)

  binary.Write(bitset, binary.BigEndian, uint32(byte_length))
  binary.Write(bitset, binary.BigEndian, uint8(bit_remainder))
  for _,item := range items {
    PackBitmapValues(&buffer,attr,item,bitset,&bi)
  }
  if(buffer != 0){
    buffer = buffer << (8 - uint(bi))
    binary.Write(bitset,binary.BigEndian, buffer)
    buffer = 0
  }
  attr.Bitset = bitset.Bytes()
}

func PackBitmapValues(buffer *uint8, attr *PackAttr, item *DBItem, bitset io.Writer, bi *int) {
  attr_val := item.Attrs[attr.Name]
  MarkBit := func (b uint8) {
    *buffer = *buffer << 1
    *buffer = *buffer | b
    *bi = *bi + 1 
    if(*bi == 8){
      *bi = 0
      binary.Write(bitset, binary.BigEndian, *buffer)
      *buffer = 0
    }
  }
  possibilities := attr.Possibilities
  for i := range (possibilities) {
    included := false
    for p := range(attr_val){
      current_val := attr_val[p]
      if(possibilities[i] == current_val && uint32(p) < attr.MaxChoices){
        included = true
      }
    }
    if(included){
      MarkBit(1)
    } else {
      MarkBit(0)
    }
  }
}

func packDB(config *TampegConfig) []byte {

  pack := &Pack{Attrs: config.Attrs}

  db, err := sql.Open("mysql", config.User + ":" + config.Password +"@/" + config.Database)
  if err != nil {
        fmt.Printf("DB error: %v\n", err)
        os.Exit(1)
  }

  var query string
  if (config.Query != ""){
    query = config.Query
  } else {
    query = "SELECT * FROM " + config.Table
  }
  rows, err := db.Query(query)
  if err != nil {
        fmt.Printf("Query error: %v\n", err)
        os.Exit(1)
  }

  columns, err := rows.Columns()

  type AttrDict struct {
    Attr *PackAttr
    Index int
  }

  dict := make(map[string]AttrDict)
  for _,a := range config.Attrs {
    name := a.Name
    index := -1

    for p, v := range columns {
        if (v == name) {
            index = p
        }
    }

    dict[name] = AttrDict{Attr: a, Index: index}
  }

  var num_vals int
  db.QueryRow("SELECT COUNT(id) from " + config.Table).Scan(&num_vals)
  data := make([]*DBItem,num_vals)
  i := 0
  for rows.Next() {
    row := make([]interface{},len(columns))
    dest := make([]interface{},len(columns))
    for i, _ := range dest {
      dest[i] = &row[i]
    }
    rows.Scan(dest...)
    final_object := new(DBItem)
    final_object.Attrs = make(map[string][]string)
    for k, v := range dict {
      if(v.Index != -1 && v.Attr.MaxChoices == 1){
        if (row[v.Index] == nil) {
          final_object.Attrs[k] = []string{}
        } else {
          singleton_result := string(row[v.Index].([]uint8))
          final_object.Attrs[k] = []string{singleton_result}
        }
      } else if (v.Index != -1){
        if (row[v.Index] == nil) {
          final_object.Attrs[k] = []string{}
        } else {
          var parsed_obj []string
          json.Unmarshal(row[v.Index].([]byte),&parsed_obj)

          final_object.Attrs[k] = parsed_obj
        }
      }
    }
    guid_index := dict[config.IdField].Index
    final_object.Guid,_ = strconv.ParseUint(string(row[guid_index].([]uint8)),10,64)
    data[i] = final_object
    i++
  }
  
  pack.Create(data)
  json,_ := json.Marshal(pack)
  return json
}

func packJSON(input_path string, config *TampegConfig) []byte {

  pack := &Pack{Attrs: config.Attrs}

  raw_json,_ := ioutil.ReadFile(input_path)
  var raw_data interface{}
  json.Unmarshal(raw_json,&raw_data)
  data := raw_data.(map[string]interface{})
  raw_items := (data["items"]).([]interface{})
  num_vals := len(raw_items)
  output_data := make([]*DBItem,num_vals)
  

  stringifyVal := func(i int, val []interface{},arr []string) []string {
      switch vv := val[i].(type){
        case string:
            arr[i] = vv    
        case int:
            arr[i] = strconv.Itoa(vv)
        case float64:
            arr[i] = strconv.Itoa(int(vv))
      }
      return arr
  }

  for i := range raw_items{
      item := raw_items[i].(map[string]interface{})
      processed_item := make(map[string][]string)
      for k,v := range item{
        switch vv := v.(type){
            case string:
                processed_item[k] = []string{vv}
            case int:
                processed_item[k] = []string{strconv.Itoa(vv)}
            case []interface{}:
                final := make([]string,len(vv))
                for ss := range vv {
                    stringifyVal(ss,vv,final)      
                }
                processed_item[k] = final
            case float64:
                processed_item[k] = []string{strconv.Itoa(int(vv))}
        }    
      }
      db_item := new(DBItem)
      db_item.Guid = uint64(item["guid"].(float64))
      db_item.Attrs = processed_item
      output_data[i] = db_item
  }


  pack.Create(output_data)
  json,_ := json.Marshal(pack)
  return json
}

func main() {
  
  var config_path string
  var config_port string
  var config_input string
  var start_server bool
  flag.StringVar(&config_path,"f","./config.json","The file to use for the config.")
  flag.StringVar(&config_input,"i","","The json file to pack instead of packing a db.")
  flag.StringVar(&config_port,"p","8080","The port to start the server on.")
  flag.BoolVar(&start_server,"s",false,"Set to true to start a server rather than just output a file.")
  flag.Parse()

  config_file, e := ioutil.ReadFile(config_path)
  if e != nil {
        fmt.Printf("File error: %v\n", e)
        os.Exit(1)
  }

  var config TampegConfig
  json.Unmarshal(config_file, &config)
  if(config.User == ""){
    config.User = "root"
  }

  packHandler := func(w http.ResponseWriter, r *http.Request){
    output := packDB(&config)
    w.Header().Set("Content-Type", "application/json")
    w.Header().Set("Content-Length", strconv.Itoa(len(output)))
    w.Write(output)
  }

  if(start_server){
    fmt.Printf("Silence. The tamperer is tamping the data for pourover on port " + config_port)
    http.HandleFunc("/", makeGzipHandler(packHandler))
    http.ListenAndServe(":"+config_port, nil)
  } else if (config_input != ""){
    output := packJSON(config_input,&config)
    // _ = ioutil.WriteFile("existence.json", output, 0644)
    os.Stdout.Write(output)
  } else {
    output := packDB(&config)
    // _ = ioutil.WriteFile("existence.json", output, 0644)
    os.Stdout.Write(output)
  }

}
