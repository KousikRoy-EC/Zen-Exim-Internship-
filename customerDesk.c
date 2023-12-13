#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LENGTH 100

void updateQuantity(FILE *fptr, const char *tempFileName, const char *HSN_Code, int Quantity);

int main()
{
    FILE *fptr;
    char Cust_Name[10];
    char HSN_Code[MAX_LENGTH];
    int Quantity;
    int gen_bill, add_Item = 0;
    int prevBill = 0;
    int found = 0;

    while (1)
    {
        fptr = fopen("Data", "r");

        if (fptr == NULL)
        {
            perror("Error opening file");
            exit(1);
        }

        printf("Name: ");
        scanf(" %[^\n]%*c", Cust_Name);

    label:
        do
        {
            fptr = fopen("Data", "r");

            if (fptr == NULL)
            {
                perror("Error opening file");
                exit(1);
            }

            printf("HSN CODE: ");
            scanf(" %[^\n]%*c", HSN_Code);

            char DB_HSN_Code[MAX_LENGTH];
            char DB_Prod_desc[MAX_LENGTH];
            char DB_Quantity[MAX_LENGTH];
            char DB_Mrp[MAX_LENGTH];

            fseek(fptr, 0, SEEK_SET);

            while (fscanf(fptr, "%s %s %s %s", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp) != EOF)
            {
                if (strcmp(HSN_Code, DB_HSN_Code) == 0)
                {
                    printf("Product Description: %s\n", DB_Prod_desc);
                    found = 1;
                    break;
                }
            }

            if (!found)
            {
                printf("Invalid HSN code");
                goto label;
            }
            fseek(fptr, 0, SEEK_SET);

            printf("\nEnter Quantity: ");
            scanf("%d", &Quantity);

            if (Quantity > atoi(DB_Quantity))
            {
                printf("\n Sorry Item not available");
                break;
            }
            else
            {
                updateQuantity(fptr, "temp.txt", HSN_Code, Quantity);
            }

            prevBill += Quantity * atoi(DB_Mrp);
            printf("\nDo you want to add more items?");
            scanf("%d", &add_Item);

        } while (add_Item);

        printf("Generate Bill?: ");
        scanf("%d", &gen_bill);

        if (gen_bill)
            printf("%s, your total bill is: %d\n", Cust_Name, prevBill);
        else
            break;
    }

    fclose(fptr);

    return 0;
}

void updateQuantity(FILE *fptr, const char *tempFileName, const char *HSN_Code, int Quantity)
{
    FILE *tempFile = fopen(tempFileName, "w");
    if (tempFile == NULL)
    {
        perror("Error opening temp file");
        exit(0);
    }

    char DB_HSN_Code[MAX_LENGTH];
    char DB_Prod_desc[MAX_LENGTH];
    char DB_Quantity[MAX_LENGTH];
    char DB_Mrp[MAX_LENGTH];

    fseek(fptr, 0, SEEK_SET);

    while (fscanf(fptr, "%s %s %s %s", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp) != EOF)
    {
        if (strcmp(HSN_Code, DB_HSN_Code) == 0)
        {
            fprintf(tempFile, "%s %s %d %s\n", DB_HSN_Code, DB_Prod_desc, atoi(DB_Quantity) - Quantity, DB_Mrp);
        }
        else
        {
            fprintf(tempFile, "%s %s %s %s\n", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp);
        }
    }

    fseek(fptr, 0, SEEK_SET);
    fclose(fptr);
    fclose(tempFile);

    remove("Data");
    rename(tempFileName, "Data");
}
