defmodule ExprC do
    @type exprC :: NumC | StringC | IdC | AppC | IfC | LamC
end

defmodule NumC do

    defstruct [:n]

    @type t :: %NumC{n: integer}

end


defmodule StringC do
    
    defstruct [:s]

    @type t :: %StringC{s: String}
end

defmodule IdC do
    defstruct [:s]

    @type t :: %IdC{s: atom}
end

defmodule AppC do

    defstruct [:fun, :args]

    @type t :: %AppC{fun: ExprC, args: list(atom)}
end

defmodule IfC do
    defstruct [:cond, :then, :else]

     @type t :: %IfC{cond: ExprC, then: ExprC, else: ExprC}
end

defmodule LamC do
    defstruct [:params, :body]

     @type t :: %LamC{params: list(atom), body: ExprC}
end




defmodule Value do
    @type value :: NumV | BoolV | StringV | ClosV | PrimV
end

defmodule NumV do
    defstruct [:n]

     @type t :: %NumV{n: integer}
end

defmodule BoolV do
    defstruct [:bool]

     @type t :: %BoolV{bool: boolean}
end

defmodule StringV do
    defstruct [:s]

     @type t :: %StringV{s: String}
end

defmodule ClosV do
    defstruct [:params, :body, :env]

     @type t :: %ClosV{params: list(atom), body: ExprC, env: ExprC}
end

defmodule PrimV do
    defstruct [:op]

     @type t :: %PrimV{op: (list(Value) -> Value)}
end


defmodule Env do
    @type env :: %{atom => [Value]}

    @spec toplevel() :: env
    def toplevel() do
        %{
            +: %PrimV{op: &Interpreter.addhelper/1},
            -: %PrimV{op: &Interpreter.subhelper/1},
            *: %PrimV{op: &Interpreter.multhelper/1},
            /: %PrimV{op: &Interpreter.divhelper/1},
            <=: %PrimV{op: &Interpreter.leq?/1},
            true: %BoolV{bool: true},
            false: %BoolV{bool: false}
        }
    end
end

    
defmodule Interpreter do


    @spec interp(ExprC, Env) :: Value

    def interp(expr, env) do

        case expr do
            %NumC{} -> %NumV{n: expr.n}
            %StringC{} -> %StringV{s: expr.s}
            %IdC{} -> env[expr.s]
            %AppC{} -> 
                fd = interp(expr.fun, env)
                case fd do
                    %PrimV{} -> fd.op.(Enum.map(expr.args, fn arg -> interp(arg, env) end))

                end
            _ -> throw IO.puts expr
        end
    end


    @spec addhelper(list(Value)) :: Value
    def addhelper(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n + List.last(args).n}
        else
            throw "add: Incorrect arguments"
        end
    end

    @spec subhelper(list(Value)) :: Value
    def subhelper(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n - List.last(args).n}
        else
            throw "sub: Incorrect arguments"
        end
    end

    @spec multhelper(list(Value)) :: Value
    def multhelper(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n * List.last(args).n}
        else
            throw "mult: Incorrect arguments"
        end
    end

    @spec divhelper(list(Value)) :: Value
    def divhelper(args) do   
        if length(args) == 2 do   
            if List.last(args).n != 0 do      
                %NumV{n: List.first(args).n / List.last(args).n}
            else
                throw "div: divide by zero error"
            end
        else
            throw "div: Incorrect arguments"
        end
    end

    @spec leq?(list(Value)) :: Value
    def leq?(args) do
        if length(args) == 2 do
            %BoolV{bool: List.first(args).n <= List.last(args).n}
        else
            throw "<=: Incorrect arguments"
        end
    end

end



###### TEST CASES  ######

ExUnit.start()

defmodule Main do
    use ExUnit.Case

    test "add+" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :+}, 
        args: [%NumC{n: 0}, %NumC{n: 2}]}, 
        Env.toplevel()) == %NumV{n: 2}
    end

    test "sub-" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :-}, 
        args: [%NumC{n: 8}, %NumC{n: 2}]}, 
        Env.toplevel()) == %NumV{n: 6}
    end

    test "mult*" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :*}, 
        args: [%NumC{n: 3}, %NumC{n: 2}]}, 
        Env.toplevel()) == %NumV{n: 6}
    end

    test "div/" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :/}, 
        args: [%NumC{n: 4}, %NumC{n: 2}]}, 
        Env.toplevel()) == %NumV{n: 2}
    end

    test "<=1" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :<=}, 
        args: [%NumC{n: 5}, %NumC{n: 4}]}, 
        Env.toplevel()) == %BoolV{bool: false}
    end

    test "<=2" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :<=}, 
        args: [%NumC{n: 3}, %NumC{n: 4}]}, 
        Env.toplevel()) == %BoolV{bool: true}
    end

    test "num" do
        assert Interpreter.interp(%NumC{n: 3}, Env.toplevel()) == %NumV{n: 3}
    end

    test "string" do
        assert Interpreter.interp(%StringC{s: "Hello World"}, Env.toplevel()) == %StringV{s: "Hello World"}
    end

    test "incorrect args" do
        catch_throw Interpreter.interp(%AppC{fun: %IdC{s: :+}, 
        args: [
            %NumC{n: 1},
            %NumC{n: 2},
            %NumC{n: 3}
        ]}, 
        Env.toplevel())
    end 

end