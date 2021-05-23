defmodule RumblWeb.VideoControllerTest do
  use RumblWeb.ConnCase

  alias Rumbl.Multimedia

  @create_attrs %{description: "some description", title: "some title", url: "some url"}
  @update_attrs %{description: "some updated description", title: "some updated title", url: "some updated url"}
  @invalid_attrs %{description: nil, title: nil, url: nil}

  def fixture(:video) do
    {:ok, video} = Multimedia.create_video(@create_attrs)
    video
  end

  describe "when user is not logged in" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.video_path(conn, :new)),
          get(conn, Routes.video_path(conn, :index)),
          get(conn, Routes.video_path(conn, :show, "123")),
          get(conn, Routes.video_path(conn, :edit, "123")),
          put(conn, Routes.video_path(conn, :update, "123", %{})),
          post(conn, Routes.video_path(conn, :create, %{})),
          delete(conn, Routes.video_path(conn, :delete, "123"))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "when user is logged in" do
    setup %{conn: conn, login_as: username} do
      user = user_fixture(username: username)
      conn = assign(conn, :current_user, user)

      {:ok, conn: conn, user: user}
    end

    @tag login_as: "max"
    test "lists all user's videos on index", %{conn: conn, user: user} do
      user_video = video_fixture(user, title: "funny cats")
      other_video = video_fixture(
        user_fixture(username: "another_user"),
        title: "other funny cats"
      )

      conn = get(conn, Routes.video_path(conn, :index))
      response = html_response(conn, 200)
      assert response =~ ~r/Listing Videos/
      assert response =~ user_video.title
      refute response =~ other_video.title
    end

    alias Rumbl.Multimedia

    @create_attrs %{
      url: "http://youtu.be",
      title: "vid",
      description: "a vid"}
    @invalid_attrs %{title: "invalid"}

    defp video_count, do: Enum.count(Multimedia.list_videos())

    @tag login_as: "max"
    test "creates user video and redirects", %{conn: conn, user: user} do
      create_conn =
        post conn, Routes.video_path(conn, :create), video: @create_attrs

      assert %{id: id} = redirected_params(create_conn)
      assert redirected_to(create_conn) ==
        Routes.video_path(create_conn, :show, id)

      conn = get conn, Routes.video_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Video"

      assert Multimedia.get_video!(id).user_id == user.id
    end

    @tag login_as: "max"
    test "does not create vid, renders errors when invalid", %{conn: conn} do
      count_before = video_count()
      conn =
        post conn, Routes.video_path(conn, :create), video: @invalid_attrs
      assert html_response(conn, 200) =~ "check the errors"
      assert video_count() == count_before
    end
  end

  test "authorizes actions against access by other users", %{conn: conn} do
    owner = user_fixture(username: "owner")
    video = video_fixture(owner, @create_attrs)
    non_owner = user_fixture(username: "sneaky")
    conn = assign(conn, :current_user, non_owner)

    assert_error_sent :not_found, fn ->
      get(conn, Routes.video_path(conn, :show, video))
    end
    assert_error_sent :not_found, fn ->
      get(conn, Routes.video_path(conn, :edit, video))
    end
    assert_error_sent :not_found, fn ->
      put(conn, Routes.video_path(conn, :update, video, video: @create_attrs))
    end
    assert_error_sent :not_found, fn ->
      delete(conn, Routes.video_path(conn, :delete, video))
    end
  end
end
