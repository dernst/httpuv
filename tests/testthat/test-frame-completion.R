# Regression test of
# https://github.com/rstudio/httpuv/pull/219

context("frame completion")

test_that("a close message with no payload is processed", {
  elapsed <- NULL

  random_port <- random_open_port()

  srv <- startServer("127.0.0.1", random_port, list(
    onWSOpen = function(ws) {
      open_time <- as.numeric(Sys.time())
      ws$onClose(function(e) {
        elapsed <<- as.numeric(Sys.time()) - open_time
        stopServer(srv)
      })
    }
  ))

  on.exit(srv$stop())

  # "Unnecessary" braces here to prevent `later` from attempting to
  # run callbacks if this test is pasted at the console
  {
    ws_client <- websocket::WebSocket$new(sprintf("ws://127.0.0.1:%s", random_port))
    ws_client$onOpen(function(event) {
      # NOTE: Depends on websocketpp internals.
      # 0 below corresponds to close::status::blank, here:
      # https://github.com/rstudio/websocket/blob/f435899aef3eaecf97af9f3febd87687ecddc3a7/src/lib/websocketpp/close.hpp#L51-L52
      ws_client$close(0)
    })
  }

  loop_start <- as.numeric(Sys.time())
  while (!later::loop_empty()) {
    loop_elapsed <- as.numeric(Sys.time()) - loop_start
    if (loop_elapsed > 10) stop("run loop timed out")
    later::run_now()
  }

  expect_true(elapsed < 1)
})
