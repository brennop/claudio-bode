(local handlers {})

(local bash {
       :type :function
       :function {
          :name :bash
          :description "Run a shell command and return its ouput"
          :parameters {
            :type :object
            :properties {
              :command {
                :type :string
                :description "The shell command to run"
              }
            }
            :required [:command]
          }}})

(fn handlers.bash [arguments]
  (: (io.popen arguments.command) :read :*a))

{:defs [bash] : handlers}
