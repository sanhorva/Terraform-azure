add-content -path c:/users/dishorva/.ssh/config -value @'

Host ${hostname}
  Hostname ${hostname}
  User ${user}
  Identityfile ${identityfile}
  '@
  
  