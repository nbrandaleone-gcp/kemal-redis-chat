## https://yduf.github.io/crystal-process/
## https://firehydrant.com/blog/testing-shell-commands-with-the-crystal-cli/

def run_cmd(cmd, args)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run(cmd, args: args, output: stdout, error: stderr)
  if status.success?
    {status.exit_code, stdout.to_s}
  else
    {status.exit_code, stderr.to_s}
  end
end
We don't need to close an IO::Memory because it doesn't represent a handle to any OS resources, just a block of memory, and we use tuples instead of arrays for the return. This means the callers know we're returning exactly two items and the first is a number and the second is a string. With an array return the caller only knows we're returning any number of items, any of which could be either an int32 or a string.

You can then use it like this:

cmd = "ping"
hostname = "my_host"
args = ["-c 2", hostname]
status, output = run_cmd(cmd, args)
puts "ping: #{hostname}: Name or service not known" unless status == 0

===

POST

curl -X POST http://localhost:3000/msg \
-H "Content-Type: application/json" \
-d '{"msg": "This is a test message"}'
