(local handlers {})

(local bash {:type :function
             :function {:name :bash
                        :description "Run a shell command and return its ouput"
                        :parameters {:type :object
                                     :properties {:command {:type :string
                                                            :description "The shell command to run"}}
                                     :required [:command]}}})

(fn handlers.bash [arguments]
  (: (io.popen arguments.command) :read :*a))

(local read {:type :function
             :function {:name :read
                        :description "Read file contents"
                        :parameters {:type :object
                                     :properties {:path {:type :string
                                                         :description "The file path"}}
                                     :required [:path]}}})

(fn handler.read [path]
  (match (io.open path)
    (nil msg) msg
    file (file:read :*a)))

{:defs [bash path] : handlers}
