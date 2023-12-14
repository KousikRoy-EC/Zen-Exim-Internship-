#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LENGTH 100

void updateQuantity(FILE *fptr, const char *tempFileName1, const char *tempFileName2, int *prevBill);
void addItemToCart(const char *tempFileName, const char *HSN_Code, int Quantity);

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
            fclose(fptr);
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
            found = 0; 

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
                addItemToCart("temp1.txt", HSN_Code, Quantity);
            }
            printf("\nDo you want to add more items?");
            scanf("%d", &add_Item);
        } while (add_Item);

        printf("Generate Bill?: ");
        scanf("%d", &gen_bill);

        if (gen_bill)
        {
            updateQuantity(fptr, "temp1.txt", "temp2.txt", &prevBill);
            printf("%s, your total bill is: %d\n", Cust_Name, prevBill);
        }
        else
        {
            break;
        }
    }

    fclose(fptr);

    return 0;
}

void addItemToCart(const char *tempFileName, const char *HSN_Code, int Quantity)
{
    FILE *tempFile = fopen(tempFileName, "a");
    if (tempFile == NULL)
    {
        perror("Error opening temp file");
        exit(0);
    }

    fprintf(tempFile, "%s %d \n", HSN_Code, Quantity);
    fclose(tempFile);
}

void updateQuantity(FILE *fptr, const char *tempFile1, const char *tempFile2, int *prevBill)
{
    FILE *tempFileName1 = fopen(tempFile1, "r");
    FILE *tempFileName2 = fopen(tempFile2, "w");

    if (tempFileName1 == NULL || tempFileName2 == NULL)
    {
        perror("Error opening temp file");
        exit(0);
    }

    char UP_HSN_Code[MAX_LENGTH];
    char UP_Quantity[MAX_LENGTH];

    struct
    {
        char HSN_Code[MAX_LENGTH];
        char Prod_desc[MAX_LENGTH];
        char Quantity[MAX_LENGTH];
        char Mrp[MAX_LENGTH];
    } mainData[MAX_LENGTH];

    int mainDataSize = 0;

    while (fscanf(fptr, "%s %s %s %s", mainData[mainDataSize].HSN_Code, mainData[mainDataSize].Prod_desc, mainData[mainDataSize].Quantity, mainData[mainDataSize].Mrp) != EOF)
    {
        mainDataSize++;
    }

    int updatedFlag[MAX_LENGTH] = {0};

    while (fscanf(tempFileName1, "%s %s", UP_HSN_Code, UP_Quantity) != EOF)
    {
        int found = 0;

        for (int i = 0; i < mainDataSize; i++)
        {
            if (strcmp(UP_HSN_Code, mainData[i].HSN_Code) == 0)
            {
                fprintf(tempFileName2, "%s %s %d %s\n", mainData[i].HSN_Code, mainData[i].Prod_desc, atoi(mainData[i].Quantity) - atoi(UP_Quantity), mainData[i].Mrp);
                *prevBill = *prevBill + atoi(mainData[i].Mrp) * atoi(UP_Quantity);
                found = 1;
                updatedFlag[i] = 1;
                break;
            }
        }
    }

    for (int i = 0; i < mainDataSize; i++)
    {
        if (!updatedFlag[i])
        {
            fprintf(tempFileName2, "%s %s %s %s\n", mainData[i].HSN_Code, mainData[i].Prod_desc, mainData[i].Quantity, mainData[i].Mrp);
        }
    }

    fclose(fptr);
    fclose(tempFileName1);
    fclose(tempFileName2);

    remove("temp1.txt");
    rename("temp2.txt", "Data");
}
