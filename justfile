format:
    cargo fmt

run:
    cargo lambda watch

send-request:
    cargo lambda invoke noughts-and-crosses --data-ascii '{"httpMethod": "GET", "path": "/"}'

build:
    cargo lambda build --arm64 --release --output-format zip

deploy:
    cd infra && tofu apply
