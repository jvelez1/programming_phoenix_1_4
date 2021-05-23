defmodule InfoSys.Counter do
  use GenServer, restart: :permanent

  # def inc(pid), do: send(pid, :inc)
  # def dec(pid), do: send(pid, :dec)

  def inc(pid), do: GenServer.cast(pid, :inc)
  def dec(pid), do: GenServer.cast(pid, :dec)

  # def val(pid, timeout \\ 5000) do
  #   ref = make_ref()
  #   send(pid, {:val, self(), ref})

  #   receive do
  #     {^ref, val} -> val
  #   after
  #     timeout -> exit(:timeout)
  #   end
  # end

  def val(pid) do
    GenServer.call(pid, :val)
  end

  def start_link(initial_value \\ 0) do
    # {:ok, spawn_link(fn -> listen(initial_value)end)}
    GenServer.start_link(__MODULE__, initial_value)
  end

  # defp listen(val) do
  #   receive do
  #     :inc ->
  #       listen(val + 1)
  #     :dec ->
  #       listen(val - 1)

  #     {:val, sender, ref} ->
  #       send(sender, {ref, val})

  #     listen(val)
  #   end
  # end

  def init(initial_value) do
    Process.send_after(self(), :tick, 1000)
    {:ok, initial_value}
  end

  def handle_cast(:inc, val) do
    {:noreply, val + 1}
  end

  def handle_cast(:dec, val) do
    {:noreply, val - 1}
  end

  def handle_call(:val, _, val) do
    {:reply, val, val}
  end

  def handle_info(:tick, val) when val <= 0, do: raise "BOOM!"

  def handle_info(:tick, val) do
    IO.puts("tick #{val}")
    Process.send_after(self(), :tick, 1000)
    {:noreply, val - 1}
  end
end
