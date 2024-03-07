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
    test       = true
    identifier = "ab"
    domain     = "test.com"
  }

  expect_failures = [var.identifier]
}

run "valid_identifier" {
  command = plan

  variables {
    test       = true
    identifier = "abc"
    domain     = "test.com"
  }
}

run "invalid_price_class" {
  command = plan

  variables {
    test        = true
    identifier  = "abc"
    domain      = "test.com"
    price_class = "FOOBAR_200"
  }

  expect_failures = [var.price_class]
}

run "valid_price_class" {
  command = plan

  variables {
    test        = true
    identifier  = "abc"
    domain      = "test.com"
    price_class = "PriceClass_200"
  }
}
