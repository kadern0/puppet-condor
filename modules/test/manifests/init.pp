class test {
  file {
      "/tmp/testing-puppet":
     ensure=> "present",
     content=> "Testing puppet and hiera\n",
       }
}

