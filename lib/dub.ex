defmodule Dub do
  use GenServer

  def start(_, _) do
    start_link()
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, []}
  end

  def handle_cast({:expect, call = {_module, _function, _args, _calls}}, expected_calls) do
    {:noreply, [call | expected_calls]}
  end

  def handle_call(:verify_calls, _from, expected_calls) do
    verified_calls =
      expected_calls
      |> Enum.map(fn {module, function, args, expected_calls} ->
        actual_calls = :meck.num_calls(module, function, args)

        if actual_calls != expected_calls do
          {:error,
           "expected #{module}.#{function} to be called #{expected_calls} times with args #{args}, but was actually called #{
             actual_calls
           }"}
        else
          :ok
        end
      end)

    {:reply, verified_calls, []}
  end

  defmacro __using__(modules, opts \\ []) do
    quote do
      meck_opts =
        Keyword.get(unquote(opts), :create_mode)
        |> case do
          true -> [:non_strict]
          _ -> []
        end

      unquote(modules)
      |> Enum.each(fn mod -> :meck.new(mod, meck_opts) end)

      setup_all do
        on_exit(fn ->
          GenServer.call(Dub, :verify_calls)
          |> Enum.each(fn result ->
            assert result == :ok
          end)
        end)
      end

      def expect(mod, fun_name, fun, called \\ 1) do
        :meck.expect(mod, fun_name, fun)
        fun_arity = :erlang.fun_info(fun)[:arity]
        GenServer.cast(Dub, {:expect, {mod, fun_name, fun_arity, called}})
      end
    end
  end
end
