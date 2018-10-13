defmodule ScenicME.Component do
  @callback animation_frame(animation_state :: any, state :: any) :: {:noreply, state :: any}

  defmacro __using__(_opts) do
    quote do
      use Scenic.Component

      @behaviour ScenicME.Component

      def init({data, parent}, opts) do
        send_event(:component_created)
        __MODULE__.init(data, opts, parent)
      end

      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        verify!(data)

        Scenic.Primitive.SceneRef.add_to_graph(
          graph,
          {__MODULE__, {data, graph.primitives[graph.add_to]}},
          opts
        )
      end

      def animation_frame(_animation_state, state), do: {:noreply, state}

      def handle_info({:animation_frame, scene_state}, state) do
        __MODULE__.animation_frame(scene_state, state)
      end

      defoverridable animation_frame: 2
    end
  end
end
