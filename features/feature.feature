Feature: Cucumber
  Scenario: First Run
    Given a file named "file.txt" with:
    """
    Hello, Aruba!
    """
    Then I debug what the hell `all` is
    And the following files should exist:
    | file.txt |
