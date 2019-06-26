defmodule Identicon do
  @doc """
  Create and save an image for a given input
  """
  def main(input) do
    input
    |> hash_string
    |> pick_color
    |> build_grid
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
  Hashes the given string using md5 put it in
  an Image and returns it

  ## Examples

      iex> Identicon.hash_string('test')
      %Identicon.Image{
        hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180, 246]
      }

  """
  def hash_string(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end

  @doc """
  Uses the hex from the received image to pick a color

  ## Examples

      iex> Identicon.pick_color(%Identicon.Image{hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180, 246]})
      %Identicon.Image{
        color: {9, 143, 107},
        hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180, 246]
      }

  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  @doc """
  Builds the grid using the hex from the received image

  ## Examples

      iex> Identicon.build_grid(%Identicon.Image{hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180, 246]})
      %Identicon.Image{
        grid: [6, 8, 12, 15, 16, 18, 19, 20, 22, 24],
        hex: [9, 143, 107, 205, 70, 33, 211, 115, 202, 222, 78, 131, 38, 39, 180, 246]
      }

  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index
      |> filter_odd_squares
      |> Enum.map(fn({_code, index}) -> index end)

    %Identicon.Image{image | grid: grid}
  end

  @doc """
  Mirrors a single row

  ## Examples

      iex> Identicon.mirror_row([1, 2, 3])
      [1, 2, 3, 2, 1]

  """
  def mirror_row(row) do
    [first, second | _tail] = row
    row ++ [second, first]
  end

  @doc """
  Returns only the even cells

  ## Examples

      iex> Identicon.filter_odd_squares([{0, 0},{1, 2},{2, 3},{3, 4},{4, 5},{6, 6}])
      [{0, 0}, {2, 3}, {4, 5}, {6, 6}]

  """
  def filter_odd_squares(grid) do
    Enum.filter(grid, fn({code, _index}) ->
      rem(code, 2) == 0
    end)
  end

  @doc """
  Builds the pixel map using the grid from the received image

  ## Examples

      iex> Identicon.build_pixel_map(%Identicon.Image{grid: [6, 8, 12, 15, 16, 18, 19, 20, 22, 24]})
      %Identicon.Image{
        grid: [6, 8, 12, 15, 16, 18, 19, 20, 22, 24],
        pixel_map: [
          {{50, 50}, {100, 100}},
          {{150, 50}, {200, 100}},
          {{100, 100}, {150, 150}},
          {{0, 150}, {50, 200}},
          {{50, 150}, {100, 200}},
          {{150, 150}, {200, 200}},
          {{200, 150}, {250, 200}},
          {{0, 200}, {50, 250}},
          {{100, 200}, {150, 250}},
          {{200, 200}, {250, 250}}
        ]
      }

  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn(square_index) ->
      horizontal = rem(square_index, 5) * 50
      vertical = div(square_index, 5) * 50

      top_left = {horizontal, vertical}
      bottom_right = {horizontal + 50, vertical + 50}

      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """
  Draw the image and return the binary
  """
  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  @doc """
  Save the given image binary with the given name
  """
  def save_image(image, name) do
    File.write("#{name}.png", image)
  end
end
