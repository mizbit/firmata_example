defmodule FirmataExample.Distance do
  use GenServer
  require Logger

  @ultra_sonic_distance 40

  defmodule State do
    defstruct [:board, value: 0, sensor_data: []]
  end

  def parse({:sonar_data, channel, data} = message) do
    GenServer.cast(__MODULE__, message)
  end

  def value() do
    GenServer.call(__MODULE__, :value)
  end

  def start_link(board, pin) do
    GenServer.start_link(__MODULE__, {board, pin, pin}, name: __MODULE__)
  end

  def init({board, trigger, echo}) do
    board |> Firmata.Board.sonar_config(trigger, echo, 200, 7)
    Logger.info "Distance Started"
    {:ok, %State{board: board}}
  end

  def handle_cast({:sonar_data, channel, data} = message, state) do
    data =
      case data >= 0 do
        true -> data
        false -> 1
      end
    state = %State{state | sensor_data: [ data | state.sensor_data ] |> Enum.slice(0, 60)}
    val =
      state.sensor_data
      |> Enum.sort()
      |> Enum.drop(10)
      |> Enum.drop(-10)
      |> Enum.reduce(0, &+/2)
      |> (&(&1 / 40)).()
    {:noreply, %State{state | value: val / 50}}#Every 50uS PWM signal is low indicates 1cm distance. Default=50
  end

  def handle_call(:value, _from, state) do
    {:reply, state.value, state}
  end
end