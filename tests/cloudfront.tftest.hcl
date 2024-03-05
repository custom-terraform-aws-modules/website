provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Environment = "Test"
    }
  }
}

run "invalid_identifier" {
  command = plan

  variables {
    identifier = "ab"
    domain     = "test"
  }

  expect_failures = [var.identifier]
}

run "valid_identifier" {
  command = plan

  variables {
    identifier = "abc"
    domain     = "test"
  }
}

run "invalid_price_class" {
  command = plan

  variables {
    identifier  = "abc"
    domain      = "test"
    price_class = "FOOBAR_200"
  }

  expect_failures = [var.price_class]
}

run "valid_price_class" {
  command = plan

  variables {
    identifier  = "abc"
    domain      = "test"
    price_class = "PriceClass_200"
  }
}
