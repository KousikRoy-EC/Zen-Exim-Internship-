#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LENGTH 100

void updateQuantity(FILE *fptr, const char *tempFileName1, const char *tempFileName2, int *prevBill);
void addItemToCart(const char *tempFileName, const char *HSN_Code, int Quantity);
void billReport(int prevBill, const char *temp, const char *Cust_Name);
void salesReport(const char *salesbill);

int main()
{
    FILE *fptr;
    char Cust_Name[10];
    char HSN_Code[MAX_LENGTH];
    int Quantity;
    int gen_bill, add_Item = 0;
    int prevBill = 0;
    int found = 0;
    char Prod_desc[MAX_LENGTH];

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
            int changeQuantity, toExit = 0;

            fseek(fptr, 0, SEEK_SET);

            while (fscanf(fptr, "%s %s %s %s", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp) != EOF)
            {
                if (strcmp(HSN_Code, DB_HSN_Code) == 0)
                {
                    strcpy(Prod_desc, DB_Prod_desc);
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

        label2:
            printf("\nEnter Quantity: ");
            scanf("%d", &Quantity);

            printf("Do you want to change Quantity ? ");
            scanf("%d", &changeQuantity);

            if (changeQuantity)
            {
                goto label2;
            }

            printf("Exit ? ");
            scanf("%d", &toExit);

            if (toExit)
            {
                exit(0);
            }

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
            salesReport("sales.txt");
            updateQuantity(fptr, "temp1.txt", "temp2.txt", &prevBill);
            billReport(prevBill, "bill.txt", Cust_Name);
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
    fflush(tempFile);
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
        for (int i = 0; i < mainDataSize; i++)
        {
            if (strcmp(UP_HSN_Code, mainData[i].HSN_Code) == 0)
            {
                fprintf(tempFileName2, "%s %s %d %s\n", mainData[i].HSN_Code, mainData[i].Prod_desc, atoi(mainData[i].Quantity) - atoi(UP_Quantity), mainData[i].Mrp);
                *prevBill = *prevBill + atoi(mainData[i].Mrp) * atoi(UP_Quantity);
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

void billReport(int prevBill, const char *temp, const char *Cust_Name)
{

    FILE *billFile = fopen(temp, "a");

    if (billFile == NULL)
    {
        perror("Error opening temp file");
        exit(0);
    }

    fprintf(billFile, "------------------ \n Name : %s  \n Total Bill : %d \n ------------------\n ", Cust_Name, prevBill);

    fflush(billFile);
    fclose(billFile);
}

void salesReport(const char *salesBill)
{
    FILE *salesReportBill = fopen(salesBill, "a+");
    FILE *tempDB = fopen("temp1.txt", "r");
    FILE *saleTemp = fopen("salesTemp.txt", "w");

    char HSN_Code[MAX_LENGTH];
    char Quantity[MAX_LENGTH];

    struct
    {
        char HSN_Code[MAX_LENGTH];
        char Quantity[MAX_LENGTH];
    } mainData[MAX_LENGTH];

    if (salesReportBill == NULL)
    {
        perror("Error opening temp file");
        exit(0);
    }

    int mainDataSize = 0;

    while (fscanf(salesReportBill, "%s %s", mainData[mainDataSize].HSN_Code, mainData[mainDataSize].Quantity) != EOF)
    {
        mainDataSize++;
    }

    while (fscanf(tempDB, "%s %s", HSN_Code, Quantity) != EOF)
    {
        int updated = 0;
        for (int i = 0; i < mainDataSize; i++)
        {
            if (strcmp(HSN_Code, mainData[i].HSN_Code) == 0)
            {
                updated = 1;
                snprintf(mainData[i].Quantity, sizeof(mainData[i].Quantity), "%d", atoi(Quantity) + atoi(mainData[i].Quantity));
                break;
            }
        }

        if (!updated)
        {
            strcpy(mainData[mainDataSize].HSN_Code, HSN_Code);
            strcpy(mainData[mainDataSize].Quantity, Quantity);
            mainDataSize++;
        }
    }

    for (int i = 0; i < mainDataSize; i++)
    {
        fprintf(saleTemp, "%s %s\n", mainData[i].HSN_Code, mainData[i].Quantity);
    }
    fclose(salesReportBill);
    fclose(saleTemp);
    fclose(tempDB);

    remove("sales.txt");
    rename("salesTemp.txt", "sales.txt");
}
