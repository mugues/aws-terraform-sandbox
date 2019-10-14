output "base_url" {
  value = "${aws_api_gateway_deployment.example.invoke_url}"
}

output "lambda_arn" {
  value = "${aws_lambda_function.main.invoke_arn}"
}