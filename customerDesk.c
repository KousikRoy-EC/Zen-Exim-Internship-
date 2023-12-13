// #include <stdio.h>
// #include <stdlib.h>
// #include <string.h>
// #include <stdbool.h>

// #define MAX_LENGTH 100

// int main()
// {
//     FILE *fptr;
//     fptr = fopen("Data", "r");

//     char Cust_Name[10];
//     char HSN_Code[MAX_LENGTH];
//     char DB_HSN_Code[MAX_LENGTH];
//     char DB_Prod_desc[MAX_LENGTH];
//     char DB_Quantity[MAX_LENGTH];
//     char DB_Mrp[MAX_LENGTH];
//     int Quantity;
//     int gen_bill, add_Item = 0;
//     int prevBill = 0;

//     while (1)
//     {
//         printf(" Name : ");
//         scanf(" %[^\n]%*c", Cust_Name);
//     addMoreItem:
//         printf(" HSN CODE : ");
//         scanf(" %[^\n]%*c", HSN_Code);

//         fseek(fptr, 0, SEEK_SET);
//         fflush(fptr);

//         while (fscanf(fptr, "%s %s %s %s", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp) != EOF)
//         {
//             if (strcmp(HSN_Code, DB_HSN_Code) == 0)
//             {
//                 printf(" Product Description : %s", DB_Prod_desc);
//                 break;
//             }
//         }
//         fseek(fptr, 0, SEEK_SET);
//         fflush(fptr);

//         printf("\n Enter Quantity ");
//         scanf("%d", &Quantity);

//         printf("\n %s %s %d %s \n", DB_HSN_Code, DB_Prod_desc, atoi(DB_Quantity) - Quantity, DB_Mrp);

//         if (Quantity > atoi(DB_Quantity))
//         {
//             printf("\n Sorry Item not available!!!");
//         }
//         else
//         {
//             FILE *tempFile = fopen("temp.txt", "w");

//             if (tempFile == NULL)
//             {
//                 perror("Error opening temp file");
//                 exit(0);
//             }

//             fseek(fptr, 0, SEEK_SET);
//             fflush(fptr);

//             while (fscanf(fptr, "%s %s %s %s", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp) != EOF)
//             {
//                 if (strcmp(HSN_Code, DB_HSN_Code) == 0)
//                 {
//                     printf("%s %s %d %s \n", DB_HSN_Code, DB_Prod_desc, atoi(DB_Quantity) - Quantity, DB_Mrp);
//                     fprintf(tempFile, "%s %s %d %s \n", DB_HSN_Code, DB_Prod_desc, atoi(DB_Quantity) - Quantity, DB_Mrp);
//                 }
//                 else
//                 {
//                     fprintf(tempFile, "%s %s %s %s \n", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp);
//                 }
//             }

//             fseek(fptr, 0, SEEK_SET);
//             fflush(fptr);

//             fclose(fptr);
//             fclose(tempFile);

//             remove("Data");
//             rename("temp.txt", "Data");
//         }

//         printf("\n Do you want to add more item ?");
//         scanf("%d", &add_Item);

//         if (add_Item)
//         {
//             add_Item = 0;
//             goto addMoreItem;
//         }

//         printf("Generate Bill ??? ");
//         scanf("%d", &gen_bill);
//         prevBill = prevBill + Quantity * atoi(DB_Mrp);
//         printf("%s Your total Bill is : %d", Cust_Name, prevBill);
//     }

//     return 0;
// }
