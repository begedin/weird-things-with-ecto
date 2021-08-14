defmodule WUEWeb.PictureControllerTest do
  @moduledoc false

  use WUEWeb.ConnCase

  alias WUE.{Pictures, Repo}

  describe "GET /pictures" do
    @path Routes.picture_path(WUEWeb.Endpoint, :index)

    test "renders 422 if missing filter", %{conn: conn} do
      assert %{
               "errors" => %{"filter" => ["can't be blank"]}
             } = conn |> get(@path) |> json_response(422)
    end

    test "renders 422 if invalid filter", %{conn: conn} do
      params = %{filter: %{}}

      assert %{
               "errors" => %{
                 "filter" => %{
                   "select_all" => [
                     "Filter requires at least one parameter, or explicitly setting 'select_all' to 'true'"
                   ]
                 }
               }
             } = conn |> get(@path, params) |> json_response(422)
    end

    test "returns []", %{conn: conn} do
      params = %{filter: %{select_all: true}}
      assert conn |> get(@path, params) |> json_response(200) == []
    end

    test "returns pictures satisfying the filter", %{conn: conn} do
      Pictures.create_picture!(%{shape: %{type: "point", x: 1, y: 1}})

      Pictures.create_picture!(%{
        shape: %{type: "line", a: %{x: 1, y: 1}, b: %{x: 5, y: 5}}
      })

      Pictures.create_picture!(%{
        shape: %{type: "box", x: 6, y: 6, w: 4, h: 4}
      })

      assert [_] =
               conn
               |> get(@path, %{filter: %{type: "point"}})
               |> json_response(200)

      assert [_] =
               conn
               |> get(@path, %{filter: %{type: "line"}})
               |> json_response(200)

      assert [_] =
               conn
               |> get(@path, %{filter: %{type: "box"}})
               |> json_response(200)

      assert [_, _] =
               conn
               |> get(@path, %{
                 filter: %{overlaps: %{min_x: 0, min_y: 0, max_x: 5, max_y: 5}}
               })
               |> json_response(200)

      assert [_] =
               conn
               |> get(@path, %{
                 filter: %{
                   overlaps: %{min_x: 6, min_y: 6, max_x: 10, max_y: 10}
                 }
               })
               |> json_response(200)
    end
  end

  describe "PUT /pictures/batch_transpose" do
    @path Routes.picture_path(WUEWeb.Endpoint, :batch_transpose)

    test "renders 422 if missing filter", %{conn: conn} do
      assert %{
               "errors" => %{"filter" => ["can't be blank"]}
             } = conn |> post(@path) |> json_response(422)
    end

    test "renders 422 if invalid filter", %{conn: conn} do
      params = %{filter: %{}}

      assert %{
               "errors" => %{
                 "filter" => %{
                   "select_all" => [
                     "Filter requires at least one parameter, or explicitly setting 'select_all' to 'true'"
                   ]
                 }
               }
             } = conn |> post(@path, params) |> json_response(422)
    end

    test "returns []", %{conn: conn} do
      params = %{filter: %{select_all: true}}
      assert conn |> post(@path, params) |> json_response(200) == []
    end

    test "batch transforms and returns affected pictures", %{conn: conn} do
      point = Pictures.create_picture!(%{shape: %{type: "point", x: 1, y: 10}})

      line =
        Pictures.create_picture!(%{
          shape: %{type: "line", a: %{x: 1, y: 10}, b: %{x: 5, y: 50}}
        })

      box =
        Pictures.create_picture!(%{
          shape: %{type: "box", x: 6, y: 60, w: 4, h: 40}
        })

      assert [_, _, _] =
               conn
               |> post(@path, %{filter: %{select_all: true}})
               |> json_response(200)

      assert %{point | shape: Pictures.Transpose.call(point.shape)} ==
               Repo.get(Pictures.Picture, point.id)

      assert %{line | shape: Pictures.Transpose.call(line.shape)} ==
               Repo.get(Pictures.Picture, line.id)

      assert %{box | shape: Pictures.Transpose.call(box.shape)} ==
               Repo.get(Pictures.Picture, box.id)
    end
  end
end
