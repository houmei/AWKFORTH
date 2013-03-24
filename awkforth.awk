#! /usr/local/bin/gawk -f
#
# FORTH inerpreter by awk
#
# 2012.05.07 Pstack & standard op
# 2012.05.09 ( comment) & ." string"
# 2012.05.10 word
#
#
BEGIN{
  Version=1.1
  Pptr=0 # Parameter Stack Pointer
  Rptr=0 # Return Stack Pointer
  Pmax=30000
  Rmax=30000

  P[0]="" # Parameter Stack
  R[0]="" # Return Stack
  M[0]="" # Memory
  # Words[],Wattr[]

  TRUE=-1
  FALSE=0

  Printbegin=""
  Printend=""
  Comment=""
  Compile=""
  Variable=""

  print "* awkforth *"
  print "-- " Version
}

{
  r=eval($0);
  if (r==0) {
    if (Compile!="") {
      print " compiled"
    } else {
      print " ok"
    }
  } else {
    print "ERR: " r
  }
}

function eval(str ,wd,wds,num,w,wj,i,j,k,r){
  r=0
  num = split(str,wd,FS,wds)
  for(i=1;i<=num;i++) {
    w=wd[i]

    if (Compile=="" && w==":") { # compile mode
      Compile=":"
      continue
    }
    if (Compile==":") { # compile word
      Compile=w
      Words[Compile]=""
      continue
    }
    if (Compile!="") { # compile
      if (w==";") {
        Wattr[Compile]="W"
        Compile=""
      } else {
        Words[Compile]=Words[Compile] " " w
      }
      continue
    }
    if (w=="VARIABLE") { # define Variable
      Variable="V"
      continue
    }
    if (Variable=="V") {
      Words[w]=0
      Wattr[w]="V"
      Variable=""
      continue
    }
    if (w=="CONSTANT") { # define Constant
      Variable="C"
      continue
    }
    if (Variable=="C") {
      Words[w]=pop()
      Wattr[w]="C"
      Variable=""
      continue
    }

    if (w=="(") { # コメント
      Comment="("; continue
    }
    if (Comment!="" && substr(w,length(w),1)==")") {
      Comment=""; continue
    }

    if (w==".\"" || w==".'") { # 文字列表示
      Printbegin=w
      Printend=last(w)
      continue
    }
    if (Printbegin!="") {
      for(j=i;j<=num;j++) {
        i++
        wj=wd[j]
        if (wj==Printbegin) continue ;
          if(last(wj)==Printend) {
          string = string head(wj)
          print string
          string=""
          PrintBegin=""
          break
        }
        string=string wj
        if (j<num) string=string wds[j];
      }
    }

    if ((r1=isnum(w))&&(r2=isop(w))) r=r1+r2;
    delete wd[i]
    delete wds[i]
  }
  return r
}

##

function push(n) {
  if (Pptr>=Pmax) {
    print "# P Stack Overflow!"
    return 0
  }
  P[Pptr]=n
  Pptr++
}
function pop( n) {
  if (Pptr<=0) {
    print "# P stack Underflow!"
    return 0
  }
  --Pptr
  n=P[Pptr]
  return n
}

function last(word){ # 文字列の最後一文字
  return substr(word,length(word),1)
}
function head(word){ # 文字列の先頭一文字
  return substr(word,1,length(word)-1)
}

function isnum(n) { # 現在、整数のみ...
  if (n~"^[-]*[0-9]+$") {
    push(n); return 0
  } else {
    return 1
  }
}

##

function isop(x ,t,n,nn,r) {
	switch(x) {
	case ".":	# . ( n -- )
		print " " pop()
		r=0;break
	case "+":	# ( n1 n2 -- n2+n1 )
		t=pop();push(pop()+t)
		r=0;break
	case "-":	# ( n1 n2 -- n2-n1 )
		t=pop();push(pop()-t)
		r=0;break
	case "*":	# ( n1 n2 -- n2*n1 )
		t=pop();push(pop()*t)
		r=0;break
	case "/":	# ( n1 n2 -- n2/n1 )
		t=pop();push(pop()/t)
		r=0;break
	case "1+":	# ( n -- n+1 )
		t=pop();push(t+1)
		r=0;break
	case "1-":	# ( n -- n-1 )
		t=pop();push(t-1)
		r=0;break
	case "NEGATE":	# ( n -- -n )
		t=pop();push(-t)
		r=0;break
	case "ABS":	# ( n -- |n| )
		t=pop();push(t+0<0?-t:t+0)
		r=0;break
	case "MAX":	# ( n1 n2 -- n3 )
		t=pop();n=pop()
		push(t>n?t:n)
		r=0;break
	case "MIN":	# ( n1 n2 -- n3 )
		t=pop();n=pop()
		push(t<n?t:n)
		r=0;break
	case "<":	# ( n1 n2 -- n3 )
		t=pop();n=pop()
		push(n<t?TRUE:FALSE)
		r=0;break
	case ">":	# ( n1 n2 -- n3 )
		t=pop();n=pop()
		push(n>t?TRUE:FALSE)
		r=0;break
	case "DROP":	# ( n -- )
		pop()
		r=0;break
	case "DUP":	# ( n -- n n )
		t=pop();push(t);push(t)
		r=0;break
	case "DDUP":	# ( n -- n n n )
		t=pop();push(t);push(t);push(t)
		r=0;break
	case "OVER":	# ( n1 n2 -- n1 n2 n1 )
		t=pop();n=pop();push(n);push(t);push(n)
		r=0;break
	case "ROT":	# ( n1 n2 n3 -- n2 n3 n1 )
		t=pop();n=pop();nn=pop()
		push(n);push(t);push(nn)
		r=0;break
	case "SWAP":	# ( n1 n2 -- n2 n1 )
		t=pop();n=pop()
		push(t);push(n)
		r=0;break
	case "VLIST":	# ( -- )
		for(t in Words) {
			if (Wattr[t]=="V") print t
		}
		r=0;break
	case "CLIST":	# ( -- )
		for(t in Words) {
			if (Wattr[t]=="C") print t
		}
		r=0;break
	case "WLIST":	# ( -- )
		for(t in Words) {
			if (Wattr[t]=="W") print t
		}
		r=0;break
	case "LIST":	# ( -- )
		for(t in Words) {
			print t,Wattr[t]
		}
		r=0;break
	default:
		r=n
	}
	return r
}
