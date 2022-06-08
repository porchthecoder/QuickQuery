# QuickQuery
Assortment of script to use the API of various vendors systems to query for host. Used with a web front end to see if a host exist in that system.  Most take a “POST” request with a form filed of “search” with value to look for.  Designed to search for host names, but will search for any matching string. Returns a bit of HTML as it’s designed to be used with JavaScript and some simple AJAX to fill out a table. 

# Install
See inside script for more information. These are CGI style scripts that are designed to be called with Javascript from a webpage. 


# commvault_query.py
Searches Commvault for a host that has been backed up. Only works with physical, not vm. 

# infoblox_query.pl 
Searches all types of DNS records for matching string. 

# prtg_query.pl
Searches PRTG. 

