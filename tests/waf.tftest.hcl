provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Environment = "Test"
    }
  }
}

run "with_waf" {
  command = plan

  variables {
    identifier    = "abc"
    domain        = "test.com"
    zone_id       = "test-zone"
    ip_rate_limit = 100
  }

  assert {
    condition     = length(aws_wafv2_web_acl.main) == 1
    error_message = "WAF web ACL was not created"
  }
}

run "without_waf" {
  command = plan

  variables {
    identifier    = "abc"
    domain        = "test.com"
    zone_id       = "test-zone"
    ip_rate_limit = 0
  }

  assert {
    condition     = length(aws_wafv2_web_acl.main) == 0
    error_message = "WAF web ACL was created unexpectedly"
  }
}
