;; Minimal MCP (Model Context Protocol) client, streamable-HTTP transport.
;; You run the MCP server yourself; this just POSTs JSON-RPC to its URL.
;; Needs: luarocks install luasocket
;; (for https:// URLs, also: luarocks install luasec)

(local http (require :socket.http))
(local ltn12 (require :ltn12))
(local cjson (require :cjson))

(local mcp {})

(var next-id 0)
(fn fresh-id []
  (set next-id (+ next-id 1))
  next-id)

;; -- transport ---------------------------------------------------------

(fn decode-body [raw]
  "Body is either plain JSON, or an SSE stream (`event: message` /
`data: {...}` lines) if the server chose to stream the response;
either way there's just the one JSON-RPC message we care about in it."
  (if (raw:match "^%s*{")
      (cjson.decode raw)
      (let [data-line (or (raw:match "data:%s*(.-)\r?\n")
                           (raw:match "data:%s*(.+)$"))]
        (cjson.decode (or data-line raw)))))

(fn post [client body-tbl]
  "POSTs `body-tbl` as JSON to client.url. Returns the decoded JSON-RPC
message, or nil for empty (e.g. 202-Accepted) replies."
  (let [body (cjson.encode body-tbl)
        chunks []
        headers {"content-type" "application/json"
                 "accept" "application/json, text/event-stream"
                 "content-length" (tostring (length body))}
        _ (when client.session-id
            (tset headers "mcp-session-id" client.session-id))
        (ok code resp-headers) (http.request
                                  {:url client.url
                                   :method :POST
                                   : headers
                                   :source (ltn12.source.string body)
                                   :sink (ltn12.sink.table chunks)})]
    (when (not ok)
      (error (.. "mcp: request failed: " (tostring code))))
    (when (and (not client.session-id) resp-headers)
      (set client.session-id (. resp-headers :mcp-session-id)))
    (let [raw (table.concat chunks)]
      (if (or (= raw "") (= code 202))
          nil
          (decode-body raw)))))

(fn rpc-call [client method params]
  (let [id (fresh-id)
        result (post client {:jsonrpc "2.0" : id : method : params})]
    (if result.error
        (error (.. "mcp error: " (or result.error.message "unknown")))
        result.result)))

(fn rpc-notify [client method params]
  (post client {:jsonrpc "2.0" : method : params}))

;; -- public client -------------------------------------------------

(fn mcp.connect [url]
  "Point this at an MCP server's endpoint URL, e.g.
(mcp.connect \"http://127.0.0.1:8765/mcp\")
The server needs to already be running - start it yourself first."
  (let [client {: url :session-id nil}]
    (rpc-call client :initialize
              {:protocolVersion "2024-11-05"
               :capabilities {}
               :clientInfo {:name "claudio" :version "0.1"}})
    (rpc-notify client :notifications/initialized {})
    client))

(fn mcp.list-tools [client]
  (. (rpc-call client :tools/list {}) :tools))

(fn mcp.call-tool [client name arguments]
  (let [result (rpc-call client :tools/call {: name : arguments})]
    (if result.isError
        (error (.. "mcp tool error: " (tostring (. result.content 1 :text))))
        (accumulate [out [] _ item (ipairs (or result.content []))]
          (do (table.insert out (or item.text (cjson.encode item)))
              out)))))

;; -- bridging into claudio's tools.defs / tools.handlers format --------

(fn mcp.tools [client prefix]
  "Converts an MCP server's tools into this harness's tool defs + handlers,
namespacing names as `prefix__toolname` to avoid collisions."
  (let [defs []
        handlers {}]
    (each [_ tool (ipairs (mcp.list-tools client))]
      (let [full-name (.. prefix "__" tool.name)]
        (table.insert defs {:type :function
                             :function {:name full-name
                                        :description (or tool.description "")
                                        :parameters (or tool.inputSchema
                                                         {:type :object :properties {}})}})
        (tset handlers full-name
              (fn [arguments]
                (table.concat (mcp.call-tool client tool.name arguments) "\n")))))
    {: defs : handlers}))

mcp
