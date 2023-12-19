function add_item() {
    local file_name="data.txt"

    echo "Enter HSN code"
    read HSN_Code

    echo "Enter Product Description"
    read Prod_Desc

    echo "Enter Quantity"
    read Quantity

    echo "Enter Mrp"
    read Mrp

    echo "$HSN_Code $Prod_Desc $Quantity $Mrp" >>"$file_name"
    echo -e "\nItem addeded SUucessfully"
}

function update_item() {

    local file_name="data.txt"

    echo "Enter HSN code to update:"
    read target_hsn

    if grep -q "$target_hsn " "$file_name"; then

        echo "Item found with HSN code : $target_hsn"
        local temp_file="temp_data.txt"

        echo "Enter new Quantity:"
        read new_quantity

        echo "Enter new MRP:"
        read new_mrp

        awk -v hsn="$target_hsn" -v qty="$new_quantity" -v mrp="$new_mrp" '
    BEGIN { OFS=" " }
    $1 == hsn { $3 = qty; $4 = mrp }
    { print }
' "$file_name" >"$temp_file"

        mv "$temp_file" "$file_name"

        echo -e "Item updated successfully.\n"
    else
        echo "HSN code not found."
    fi
}

function show_item() {

    local file="data.txt"

    while read -r line; do
        echo -e "$line"
    done <$file
}

while true; do
    echo -e "\nEnter the operation you want??"
    echo "1. Add new Item"
    echo "2. Update Item"
    echo "3. Display Warehouse Item"
    echo "4. Exit"
    echo "Enter Your Choice : "
    read choice

    if [ $choice -eq 1 ]; then
        add_item
    elif [ $choice -eq 2 ]; then
        update_item
    elif [ $choice -eq 3 ]; then
        show_item
    else
        exit 0
    fi
done
