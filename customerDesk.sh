file_name="data.txt"
temp_file="item.txt"
sales_file="salesReport.txt"
bill_file="billReport.txt"

totaBill=0

addItem(){
echo "$1 $2" >> "$temp_file"
}

salesReport(){
local db="item.txt"
local temp_file="temp_data.txt"
local sales_file="salesReport.txt" 

while IFS=" " read -r hsn new_qty; do
    if grep -q "$hsn " "$sales_file"; then
        result=$(grep "$hsn" "$sales_file")
        up_quant=$(echo "$result" | awk -F' ' '{print $2}')
        new_qty=$(expr $new_qty + $up_quant)
        sed -i "/$hsn/ s/[^ ]*/$new_qty/" "$sales_file"
    fi
    echo "$hsn $new_qty" >> "$temp_file"
done < "$db"

 cat "$temp_file" >> "$sales_file"
    rm "$temp_file"

}

updateWarehouse(){
local temp_file="temp_data.txt"
local db="item.txt"

while IFS=" " read -r hsn prod_desc new_qty mrp; do
    if grep -q "$hsn " "$db"; then
        result=$(grep "$hsn" "$db")
        up_quant=$(echo "$result" | awk -F' ' '{print $2}')  
        new_qty=$(expr $new_qty - $up_quant)
        totalBill=$((mrp * up_quant + totalBill))
    fi
    echo "$hsn $prod_desc $new_qty $mrp" >> "$temp_file"
done < "$file_name"

rm "data.txt"
rm "item.txt"
mv "temp_data.txt" "data.txt"
}

billReport(){
echo "$1 $2" >> "$bill_file"
totalBill=0
}


while true
do

echo "Enter Your Name!"
read custName

while true; do

echo "Enter HSN code"
read HSN_CODE

result=$(grep "$HSN_CODE" "$file_name")

if [ -n "$result" ]; then
    Prod_Desc=$(echo "$result" | awk -F' ' '{print $2}')
    echo "Prod_Desc: $Prod_Desc"
else
    echo "Entry with HSN_CODE $HSN_CODE not found in $file_name"
    break
fi

echo "Enter Quantity"
read Quantity

echo "Do you want to change Quantity ? "
read changeQuantity

if [ "$changeQuantity" -eq 1 ];
then
   echo "Enter Quantity"
   read Quantity
fi

echo "Exit ??"
read exit

if [ "$exit" -eq 1 ];
then
   exit 0
fi

quantity=$(echo "$result" | awk -F' ' '{print $3}')
if [ "$Quantity" -gt "$quantity"  ];
then 
	echo "Item not available"
	break
else
	addItem $HSN_CODE $Quantity
	echo "Do you want to add Item ? "
	read add_Item
fi

if [ "$add_Item" -eq 0 ]; then
            break
fi

done
echo "Generate Bill!"
read bill

if [ "$bill" -ne 0 ];
    then
    salesReport
    updateWarehouse
    billReport $custName $totalBill
else

exit 0
fi
done
