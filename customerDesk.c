#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MAX_LENGTH 100

int main()
{
    FILE *fptr;
    fptr = fopen("Data", "r");

    int Choice;
    char Cust_Name[10];
    char HSN_Code[MAX_LENGTH];
    char DB_HSN_Code[MAX_LENGTH];
    char DB_Prod_desc[MAX_LENGTH];
    char DB_Quantity[MAX_LENGTH];
    char DB_Mrp[MAX_LENGTH];
    int Quantity;
    int gen_bill = 0;

    while (1)
    {
        printf(" Name : ");
        scanf(" %[^\n]%*c", Cust_Name);
        printf(" HSN CODE : ");
        scanf(" %[^\n]%*c", HSN_Code);

        while (fscanf(fptr, "%s %s %s %s", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp) != EOF)
        {
            if (strcmp(HSN_Code, DB_HSN_Code) == 0)
            {
                printf(" Product Description : %s", DB_Prod_desc);
            }
        }

        printf("\n Enter Quantity ");
        scanf("%d", &Quantity);

        printf("Generate Bill ??? ");
        scanf("%d", &gen_bill);

        if (gen_bill)
        {

            FILE *tempFile = fopen("temp2.txt", "w");

            if (tempFile == NULL)
            {
                perror("Error opening temp file");
                exit(0);
            }

            while (fscanf(fptr, "%s %s %s %s", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp) != EOF)
            {
                if (strcmp(HSN_Code, DB_HSN_Code) == 0)
                {
                    fprintf(tempFile, "%s %s %d %s \n", DB_HSN_Code, DB_Prod_desc, atoi(DB_Quantity) - Quantity, DB_Mrp);
                }
                else
                {
                    fprintf(tempFile, "%s %s %s %s \n", DB_HSN_Code, DB_Prod_desc, DB_Mrp, DB_Quantity);
                }
            }

            fclose(tempFile);

            remove("Data");
            rename("temp2.txt", "Data");

            printf("Your total Bill is : %d", Quantity * atoi(DB_Mrp));
        }
    }

    return 0;
}
