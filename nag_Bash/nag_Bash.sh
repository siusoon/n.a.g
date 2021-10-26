#!/bin/bash
site="https://nag.iap.de/";
request=$(curl -d "ac=create&query=warhol+flowers&comp=4&width=800&ext=jpg" -X POST ${site});
image=$(grep -E -o 'gen/anonymous-warhol_flowers.+\.jpg' <<< {$request});
wget $site$image;
