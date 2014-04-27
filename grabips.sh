#!/bin/bash
#Grapips parses text files and returns valid external IP Addresses.
# ~jsbrown
#
function create_locfile(){
cat /tmp/GeoDecIP2Country.txt
}
#
function get_info(){ echo "" 
 echo "" > /tmp/$OUTPUTIP.txt
 [ "$RECURSE" != "" ] && echo "Enter Directory Path to Recursively Process:  " 
 [ "$RECURSE" == "" ] && echo "Enter an IP Address or File Name to process:  " 
 read INPUT;
 #if no input then exit
 [ "$INPUT" == "" ] && exit
 INPUT=$(echo $INPUT |tr -d ' ')
  #copies geoip information to tmp directory if it does not exist
 [ ! -f /tmp/GeoDecIP2Country.txt ] && create_locfile  && echo "IP2CountryDB created in  /tmp/GeoDecIP2Country.txt"
 #if input is a file name output the same as input
 [ -f "$INPUT" ] && OUTPUT=$INPUT
 [ ! -d $INPUT ] && [ ! -f $INPUT ] && INPUT=$(echo $INPUT | awk -F '\.' '/(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/{print $1"\."$2"\."$3"\."$4}') && IPtoCountry 
 # if input is not a dir and -r is set, exit
 [ "$RECURSE" != "" ] && [ ! -d $INPUT ] && echo "Not a valid directory path" && exit
 # if input is a dir and -r is not set, exit
 [ "$RECURSE" == "" ] && [ -d $INPUT ] && echo "Use -r switch to recursively parse a directory" && exit
 # if the -r switch is set name output file Console switch not set
 [ "$RECURSE" != "" ] && [ "$CONSOLE" == "" ] && echo "Output HTML File Name" && read OUTPUT 
 #if Console value is not set, create/clear temp file and output file
 [ "$OUTPUT" != "" ] &&  [ "$CONSOLE" == "" ] && echo "" > /tmp/$OUTPUT.html

}
# converts dotted quad to an integer for ip2country lookup
function IptoInt(){ 
echo $1|awk -F'\.' '{print ($1 * 2^24)+($2 * 2^16)+($3 * 2^8)+$4}'
} 
# IP2Country lookup for a single IP
function IPtoCountry(){
[ "$INPUT" == "" ]  &&  echo "Not Found" && exit 
DEC_IP=$(IptoInt $INPUT) 
HOSTNME=$(dig +short -x $INPUT | awk '{print $NF }' | tr -d '\n')
[ "$HOSTNME" == "" ] || [ "$HOSTNME" == "reached" ] && HOSTNME="Not-Found"
COUNTRY=$(awk -v decip="$DEC_IP" -v IP="$INPUT" -v HN="$HOSTNME" -F'\t' '{ if ($1 <=decip &&  $2>=decip ) printf "%-18s%-3s%-25s%-15s\n", IP,$3,$4,HN }' /tmp/GeoDecIP2Country.txt)
[ "$COUNTRY" == "" ] && echo "Not Found....  Enter a valid IP Address, File Name or Directory" && exit
echo  -e "IP\t\tCOUNTRY\t\t\t\tDNS"
awk -v decip="$DEC_IP" -v IP="$INPUT" -v HN="$HOSTNME" -F'\t' '{ if ($1 <=decip &&  $2>=decip ) printf "%-18s%-3s%-25s%-15s\n", IP,$3,$4,HN }' /tmp/GeoDecIP2Country.txt
}
# outputs IP info from a single file or recursively parses a directory
function IPListtoCountry(){
[ "$RECURSE" == "" ] && grep -Eoa "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" $INPUT | grep -Ev "^0|\.0[0-9]|^10\.|^127\.|^169\.|^172\.(1[6-9]|2[0-9]|3[01])|^192.168.|^2(2[4-9]|3[0-9])|^2(4[0-9]|5[0-5])"|tee -a /tmp/$OUTPUTIP.txt
[ "$RECURSE" != "" ] && find *.* $INPUT -type f 2>/dev/null | while read d; do grep -Eoa "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" $d 2>/dev/null| grep -Ev "^0|\.0[0-9]|^10\.|^127\.|^169\.|^172\.(1[6-9]|2[0-9]|3[01])|^192.168.|^2(2[4-9]|3[0-9])|^2(4[0-9]|5[0-5])"|tee -a /tmp/$OUTPUTIP.txt ;done
echo "sorting....."
cat /tmp/$OUTPUTIP.txt | egrep -v "^(\r?\n)?$" | sort -rn | uniq -c|tee /tmp/$OUTPUTIP.txt
echo ""
[ "$CONSOLE" == "" ] && echo "Writing Output to $PWD/$OUTPUT.html....."
echo ""
echo  -e "IP ADDRESS  \t\tCOUNTRY\t\t\tDNS RESOLUTION"
echo ""
cat /tmp/$OUTPUTIP.txt | while read LINE; do
REPEATS=$(echo $LINE |awk '{print $1 }')
IPADDR=$(echo $LINE | awk '{print $2 }')
DEC_IP=$(IptoInt $IPADDR)
HOSTNME=$(dig +short -x $IPADDR | awk '{print $NF }' | tr -d '\n')
[ "$HOSTNME" == "" ] || [ "$HOSTNME" == "reached" ] && HOSTNME="Not-Found"
COUNTRY=$(awk -v decip="$DEC_IP" -F'\t' '{ if ($1 <=decip &&  $2>=decip ) print $3,$4}' /tmp/GeoDecIP2Country.txt) 
printf "%-4s%-15s%3s %-30s%-50s         \n" $REPEATS $IPADDR $COUNTRY $HOSTNME
IPHTML=$(echo "<tr><td>$REPEATS</td><td>$IPADDR</td><td>$COUNTRY</td><td>$HOSTNME</td><td><a href=https://www.robtex.com/ip/iPaDDr.html#whois style=text-decoration:none; target=_blank> Robtex </a> - <a href=http://www.senderbase.org/lookup/?search_string=iPaDDr style=text-decoration:none; target=_blank> Senderbase </a> - <a href=https://www.virustotal.com/en/ip-address/iPaDDr/information style=text-decoration:none; target=_blank> VT </a><br><a href=http://www.projecthoneypot.org/ip_iPaDDr style=text-decoration:none; target=_blank> ProjectHoneyPot </a> - <a href=https://www.google.com/#q=iPaDDr style=text-decoration:none; target=_blank> Google</td></tr>"|sed "s/iPaDDr/$IPADDR/g")
[ "$CONSOLE" == "" ] && echo $IPHTML>>/tmp/$OUTPUT.html
done
#[ "$CONSOLE" == "" ] && HTOP=$(echo "<html><body><table border=1 cellpadding=5 cellspacing=0><tr><td>Count  </td><td>IP Address</td><td>Country</td><td>Host Name</td><td><a href=\https://www.robtex.com target=_blank> Robtex </a><br><a href=\http://www.senderbase.org target=_blank> Senderbase </a><br><a href=\https://www.virustotal.com target=_blank> VT </a><br><a href=\http://www.projecthoneypot.org target=_blank> ProjectHoneyPot </a><br><a href=\http://www.ipvoid.com/ target=blank> IPVoid </a></td></tr>") 
[ "$CONSOLE" == "" ] && echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><title>Grabips Output</title>'>/tmp/HTOP
[ "$CONSOLE" == "" ] && echo '<style>* {margin:0; padding:0; outline:none}body {font:10px Verdana,Arial; margin:25px; background:#fff repeat-x; color:#091f30}.sortable {width:980px; border-left:1px solid #c6d5e1; border-top:1px solid #c6d5e1; border-bottom:none; margin:0 15px}.sortable th {background-color:#999999; text-align:left; color:#cfdce7; border:1px solid #fff; border-right:none}.sortable th h3 {font-size:10px; padding:6px 8px 8px}.sortable td {padding:4px 6px 6px; border-bottom:1px solid #c6d5e1; border-right:1px solid #c6d5e1}.sortable .desc, .sortable .asc {background-color:#666666;}.sortable .head:hover, .sortable .desc:hover, .sortable .asc:hover {color:#fff}.sortable .evenrow td {background:#fff}.sortable .oddrow td {background:#ecf2f6}.sortable td.evenselected {background:#ecf2f6}.sortable td.oddselected {background:#dce6ee}#controls {width:980px; margin:0 auto; height:20px}#perpage {float:left; width:200px}#perpage select {float:left; font-size:11px}#perpage span {float:left; margin:2px 0 0 5px}#navigation {float:left; width:580px; text-align:center}#navigation img {cursor:pointer}#text {float:left; width:200px; text-align:right; margin-top:2px}</style>'>>/tmp/HTOP
[ "$CONSOLE" == "" ] && echo '<script type="text/javascript"> var TINY={};function T$(i){return document.getElementById(i)}function T$$(e,p){return p.getElementsByTagName(e)}TINY.table=function(){function sorter(n){this.n=n;this.pagesize=10000;this.paginate=0}sorter.prototype.init=function(e,f){var t=ge(e),i=0;this.e=e;this.l=t.r.length;t.a=[];t.h=T$$("thead",T$(e))[0].rows[0];t.w=t.h.cells.length;for(i;i<t.w;i++){var c=t.h.cells[i];if(c.className!="nosort"){c.className=this.head;c.onclick=new Function(this.n+".wk(this.cellIndex)")}}for(i=0;i<this.l;i++){t.a[i]={}}if(f!=null){var a=new Function(this.n+".wk("+f+")");a()}if(this.paginate){this.g=1;this.pages()}};sorter.prototype.wk=function(y){var t=ge(this.e),x=t.h.cells[y],i=0;for(i;i<this.l;i++){t.a[i].o=i;var v=t.r[i].cells[y];t.r[i].style.display="";while(v.hasChildNodes()){v=v.firstChild}t.a[i].v=v.nodeValue?v.nodeValue:""}for(i=0;i<t.w;i++){var c=t.h.cells[i];if(c.className!="nosort"){c.className=this.head}}if(t.p==y){t.a.reverse();x.className=t.d?this.asc:this.desc;t.d=t.d?0:1}else{t.p=y;t.a.sort(cp);t.d=0;x.className=this.asc}var n=document.createElement("tbody");for(i=0;i<this.l;i++){var r=t.r[t.a[i].o].cloneNode(true);n.appendChild(r);r.className=i%2==0?this.even:this.odd;var cells=T$$("td",r);for(var z=0;z<t.w;z++){cells[z].className=y==z?i%2==0?this.evensel:this.oddsel:""}}t.replaceChild(n,t.b);if(this.paginate){this.size(this.pagesize)}};sorter.prototype.page=function(s){var t=ge(this.e),i=0,l=s+parseInt(this.pagesize);if(this.currentid&&this.limitid){T$(this.currentid).innerHTML=this.g}for(i;i<this.l;i++){t.r[i].style.display=i>=s&&i<l?"":"none"}};sorter.prototype.move=function(d,m){var s=d==1?(m?this.d:this.g+1):(m?1:this.g-1);if(s<=this.d&&s>0){this.g=s;this.page((s-1)*this.pagesize)}};sorter.prototype.size=function(s){this.pagesize=s;this.g=1;this.pages();this.page(0);if(this.currentid&&this.limitid){T$(this.limitid).innerHTML=this.d}};sorter.prototype.pages=function(){this.d=Math.ceil(this.l/this.pagesize)};function ge(e){var t=T$(e);t.b=T$$("tbody",t)[0];t.r=t.b.rows;return t};function cp(f,c){var g,h;f=g=f.v.toLowerCase(),c=h=c.v.toLowerCase();var i=parseFloat(f.replace(/(\$|\,)/g,"")),n=parseFloat(c.replace(/(\$|\,)/g,""));if(!isNaN(i)&&!isNaN(n)){g=i,h=n}i=Date.parse(f);n=Date.parse(c);if(!isNaN(i)&&!isNaN(n)){g=i;h=n}return g>h?1:(g<h?-1:0)};return{sorter:sorter}}();</script>'>>/tmp/HTOP
[ "$CONSOLE" == "" ] && echo '</head><body><table cellpadding="0" cellspacing="0" border="0" id="table" class="sortable"><thead><tr><th><h3>Count</h3></th><th><h3>IP Address</h3></th><th><h3>Country</h3></th><th><h3>DNS</h3></th><th class="nosort"><h3>Links</h3></th></tr></thead><tbody>'>>/tmp/HTOP
[ "$CONSOLE" == "" ] && echo '</tbody></table><script type="text/javascript">  var sorter = new TINY.table.sorter("sorter");sorter.head = "head";sorter.asc = "asc";sorter.desc = "desc";sorter.even = "evenrow";sorter.odd = "oddrow";sorter.evensel = "evenselected";sorter.oddsel = "oddselected";sorter.paginate = true;sorter.currentid = "currentpage";sorter.limitid = "pagelimit";sorter.init("table",1);</script></body></html>' >/tmp/HFOOT
[ "$CONSOLE" == "" ] && cat /tmp/HTOP /tmp/$OUTPUT.html /tmp/HFOOT > $PWD/$OUTPUT.html
#[ "$CONSOLE" == "" ] && cat /tmp/seg1.txt   > /tmp/tmp.txt
}
# Grabips.sh 
clear
echo "Grapips Returns external IP address info"
echo "Enter an IP address, file name or directory path to return Country, DNS and other info"
echo ""
echo " -c for console output only"
echo " -r to recursively search all files in a given path for external IP addresses" 
echo ""
[ "$1" == "-r" ] && RECURSE="Yes"
[ "$1" == "-c" ] &&  CONSOLE="Yes"
[ "$1" == "-rc" ] ||  [ "$1" == "-cr" ] &&  CONSOLE="Yes" &&  RECURSE="Yes"
get_info
[ -f $INPUT ] && IPListtoCountry && printf "\nProcess complete!\nOutput written to $PWD/$OUTPUT.html.....\n\n" && exit
[ -d $INPUT ] && IPListtoCountry && printf "\nProcess complete!\nOutput written to $PWD/$OUTPUT.html.....\n\n" && exit