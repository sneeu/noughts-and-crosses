use lambda_http::{run, service_fn, tracing, Body, Error, Request, Response};

async fn handler(_event: Request) -> Result<Response<Body>, Error> {
    Ok(Response::builder()
        .status(200)
        .header("content-type", "text/html")
        .body(Body::Text("Hello, world!".into()))
        .expect("failed to render response"))
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing::init_default_subscriber();

    run(service_fn(handler)).await
}
