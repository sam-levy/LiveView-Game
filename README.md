# Simple LiveView Game

A humble Phoenix LiveView multiplayer game you can play on you browser.

## Installation

### Asdf

If you don't have Elixir and Erlang installed, you can install both via asdf.
In order to install asdf please follow the instructions in the
[asdf documentation page](http://asdf-vm.com/guide/getting-started.html#_1-install-dependencies).

With `asdf` installed, please enter this commands on your terminal to install the required plugins:

```
asdf plugin-add erlang
asdf plugin-add elixir
```

Then, install the required versions of Erlang and Elixir with:

```
asdf install erlang 24.0.1
asdf install elixir 1.13.2
```

With Erlang and Elixir installed, go to the repository folder and type:

```
mix deps.get
```

After installing the dependencies you are rady to play!

## Testing

Run all the tests with `mix test`.

## Deploying

This project was deployed using Fly.io. Please [check Fly.io Phoenix deployment guide](https://fly.io/docs/getting-started/elixir/).

For other deployement guides please [check Phoenix deployment guides](https://hexdocs.pm/phoenix/).

## Playing

Start Phoenix server with `mix phx.server` or inside IEx with `iex -S mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

In the `Lobby` page you can chose a name for you hero or go wiht the random name that was generated.

You can control your hero with the arrow keys, vim keys (`h`, `j`, `k` and `l`) or WASD keys.

You can attack with the spacebar key.

## Live demo

https://dawn-feather-8121.fly.dev/

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
