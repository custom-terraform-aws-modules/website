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
    domain     = "example.com"
    zone_id    = "WRW3249RFWEOJ234"
  }

  expect_failures = [var.identifier]
}

run "valid_identifier" {
  command = plan

  variables {
    identifier = "abc"
    domain     = "example.com"
    zone_id    = "WRW3249RFWEOJ234"
  }
}

run "invalid_price_class" {
  command = plan

  variables {
    identifier  = "abc"
    domain      = "example.com"
    zone_id     = "WRW3249RFWEOJ234"
    price_class = "FOOBAR_200"
  }

  expect_failures = [var.price_class]
}

run "valid_price_class" {
  command = plan

  variables {
    identifier  = "abc"
    domain      = "example.com"
    zone_id     = "WRW3249RFWEOJ234"
    price_class = "PriceClass_200"
  }
}

run "invalid_tags" {
  command = plan

  variables {
    identifier = "abc"
    domain     = "example.com"
    zone_id    = "WRW3249RFWEOJ234"
    tags = {
      Name = "Foo"
    }
  }

  expect_failures = [var.tags]
}

run "valid_tags" {
  command = plan

  variables {
    identifier = "abc"
    domain     = "example.com"
    zone_id    = "WRW3249RFWEOJ234"
    tags = {
      Project = "Foo"
    }
  }
}
