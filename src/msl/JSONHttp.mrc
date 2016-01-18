/** /JSONHttpMethod @Handle @Method
***     Sets a pending Handle's HTTP request method
***
***     @Handle - (required):
***         Priorly created JSON handle
***
***     @Method - (required):
***         The method to use
***         Valid methods are GET, POST, PUT or DEL
**/ 
alias JSONHttpMethod {
  if ($isid) return

  var %Error
  if (!$_JSON.Start) {
    %Error = $JSONError
  }
  
  ;; validate parameters
  elseif ($0 !== 2) {
    %Error = Invalid parameters
  }
  elseif (!$regex($1, /^[a-z][a-z\d_.:\-]+$/i)) {
    %Error = Invalid handler name: Must start with a letter and contain only letters numbers _ . : and -
  }
  elseif (!$_JSON.Exists($1)) {
    %Error = Handle does not exist  
  }
  elseif (!$istok(GET POST PUT DEL, $2, 32)) {
    %Error = Invalid method
  }
  
  ;; Attempt to set the header
  elseif (!$_JSON.Set($1, HttpMethod, $upper($2)) {
    %Error = $JSONError
  }

  :error
  %Error = $iif($error, $v1, %Error)
  if (%error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
  }
}

/** /JSONHttpHeader @Handle @Header @Value
***     Sets a HTTP header for a Handle's pending HTTP request
***
***     @Handle - (required):
***         Priorly created JSON handle
***
***     @Header - (required):
***         The name of the header to set
***
***     @Value - (required):
***         The value of the header to set
**/ 
alias JSONHttpHeader {
  if ($isid) return

  var %Error, %Header
  if (!$_JSON.Start) {
    %Error = $JSONError
  }
  
  ; Validate parameters
  elseif ($0 < 3) {
    %Error = Invalid parameters
  }
  elseif (!$regex($1, /^[a-z][a-z\d_.:\-]+$/i)) {
    %Error = Invalid handler name: Must start with a letter and contain only letters numbers _ . : and -
  }
  elseif (!$_JSON.Exists($1)) {
    %Error = Handle does not exist  
  }
  else {
  
    ; Trim excessive whitespace and any trailing ":"
    %Header = $regsubex($2, /(?:^\s+)|(?:\s*:\s*$)/g, )
    if (: isin %header) {
      %Error = Header name invalid(contains ':')
    }
    
    ; Attempt to set the header
    elseif (!$_JSON.Set($1, HttpHeader, %Header, $3-)) {
      %Error = $JSONError
    }
  }

  :error
  %Error = $iif($error, $v1, %Error)
  if (%error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
  }
}

/** /JSONHttpFetch -bf @Handle @Source
***     Attempts to fetch a Handle's pending HTTP request and parse the result
***
***     -b: @Source is a bvar
***     -f: @Source is a file
***
***     @Handle - (required):
***         Priorly created JSON handle
***
***     @Source - (optional):
***         The data source to send
***         Valid values are a bvar(switch dependant), a file path(switch dependant), or if assumed to be plain text
**/
alias JSONHttpFetch {
  if ($isid) return
  
  var %Error, %Switches, %BVar, %UnsetBVar
  if (!$_JSON.Start) {
    %Error = $JSONError
  }
  else {

    ;; Remove switches from the parameter input
    if (-* iswm $1) {
      %Switches = $mid($1, 2-)
      tokenize 32 $2-
    }
    
    if ($0 < 1) {
      %Error = Missing Parameters
    }

    ;; Validate switches
    elseif ($regex(%Switches, ([^bf]))) {
      %Error = Invalid switches specified: $regml(1)
    }
    elseif ($regex(%Switches, ([bf]).*?\1)) {
      %Error = Duplicate switch specified: $regml(1)
    }
    elseif ($regex(%Switches, /([bf])/g) > 1) {
      %Error = Conflicting switches: $regml(1) $+ , $regml(2)
    }
    elseif (%Switches && $0 < 2) {
      %Error = Missing parameters
    }

    ;; Validate name parameter
    elseif (!$regex($1, /^[a-z][a-z\d_.:\-]+$/i)) {
      %Error = Invalid handler name: Must start with a letter and contain only letters numbers _ . : and -
    }
    elseif (b isincs %Switches && $0 !== 2) {
      %Error = Invalid bvar: Cannot contain spaces
    }
    elseif (b isincs %Switches && $left($2, 1) !== &) {
      %Error = Invalid bvar: Must start with &
    }
    elseif (b isincs %Switches && !$bvar($2,0)) {
      %Error = Invalid bvar: Contains no data
    }
    elseif (f isincs %Switches && !$isfile($2-)) {
      %Error = File does not exist
    }
    
    ;; If no data is to be passed, just fetch
    elseif (!%Switches) {
      if (!$_JSON.Call($1, httpFetch)) {
        %Error = $JSONError
      }
    }
    
    else {
      ;; Store the data to send in a bvar
      if (b isincs %Switches) {
        %BVar = $2
      }
      else {
        %BVar = $_JSON.TmpBVar
        %Unset%BVar = $true
        
        if (f isincs %Switches) {
           bread $qt($file($2-).longfn) 0 $file($2-).size %BVar
        }
        else {
          bset -t %BVar 1 $2-
        }
      }
      
      ;; attempt to fetch
      if (!$_JSON.Call($1, httpFetch, &bstr, %BVar)) {
        %Error = $JSONError
      }
    }
  }
  
  :error
  %Error = $iif($error, $v1, %Error)
  if (%UnsetBVar) bunset %BVar
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
  }
}