module MotionProvisioning
  module Utils
    class Answer
      def initialize(answer)
        @answer = answer.downcase
      end

      def yes?
        @answer == 'y'
      end

      def no?
        @answer == 'n'
      end
    end

    module_function
    def log(what, msg)
      require 'thread'
      @print_mutex ||= Mutex.new
      # Because this method can be called concurrently, we don't want to mess any output.
      @print_mutex.synchronize do
        $stderr.puts(what(what) + ' ' + msg)
      end
    end

    def ask(what, question)
      what = "\e[1m" + what.rjust(10) + "\e[0m" # bold
      $stderr.print(what(what) + ' ' + question + ' ')
      $stderr.flush

      result = $stdin.gets
      result.chomp! if result
      Answer.new(result)
    end

    def ask_password(what, question)
      require 'io/console' # needed for noecho

      # Save current buffering mode
      buffering = $stderr.sync

      # Turn off buffering
      $stderr.sync = true
      `stty -icanon`

      begin
        $stderr.print(what(what) + ' ' + question + ' ')
        $stderr.flush
        pw = ""

        $stderr.noecho do
          while ( char = $stdin.getc ) != "\n" # break after [Enter]
            putc "*"
            pw << char
          end
        end
      ensure
        print "\n"
      end

      # Restore original buffering mode
      $stderr.sync = buffering

      `stty -icanon`
      pw
    end

    def what(what)
      "\e[1m" + what.rjust(10) + "\e[0m" # bold
    end
  end
end
