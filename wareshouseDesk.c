#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void add_item(FILE *fptr);
void update_item(FILE *fptr);
void display_item(FILE *fptr);

int main()
{
  FILE *fptr;
  fptr = fopen("Data", "a");

  if (fptr == NULL)
  {
    printf("err");
    exit(0);
  }

  int Operation;

  while (1)
  {
    printf("\nEnter The Operation you want\n");

    printf("1. Add new Item\n");
    printf("2. Update Item\n");
    printf("3. Display Warehouse Item\n");
    printf("4. Exit\n");
    printf("\nEnter Your Choice : ");

    scanf("%d", &Operation);

    switch (Operation)
    {
    case 1:
      add_item(fptr);
      break;

    case 2:
      update_item(fptr);
      break;

    case 3:
      display_item(fptr);
      break;

    case 4:
      exit(0);
      break;

    default:
      break;
    }
  }

  fclose(fptr);

  return 0;
}

void add_item(FILE *fptr)
{
  int HSN_Code;
  char Product_Description[100];
  int Quantity;
  float MRP;

  printf("\nEnter HSN Code: ");
  scanf("%d", &HSN_Code);
  printf("Enter Product Description: ");
  scanf(" %[^\n]%*c", Product_Description);
  printf("Enter Quantity: ");
  scanf("%d", &Quantity);
  printf("Enter MRP: ");
  scanf("%f", &MRP);

  fprintf(fptr, "%d %s %d %f \n", HSN_Code, Product_Description, Quantity, MRP);
  printf("\nItem added Sucessfully\n");
  fflush(fptr);
}

void display_item(FILE *fptr)
{
  fptr = fopen("Data", "r");
  char Data[100];

  while (fgets(Data, sizeof(Data), fptr))
  {
    printf("%s", Data);
  }
}

void update_item(FILE *fptr)
{
  fptr = fopen("Data", "r");

  if (fptr == NULL)
  {
    perror("Error opening file");
    exit(0);
  }

  FILE *tempFile = fopen("temp.txt", "w");

  if (tempFile == NULL)
  {
    perror("Error opening temp file");
    exit(0);
  }

  char Input_HSN[__INT_MAX__];
  char DB_HSN_Code[__INT_MAX__];
  char DB_Prod_desc[__INT_MAX__];
  char DB_Quantity[__INT_MAX__];
  char DB_Mrp[__INT_MAX__];
  int new_quantity;
  float new_mrp;

  printf("Enter HSN code of the item to update");
  scanf(" %[^\n]%*c", Input_HSN);

  while (fscanf(fptr, "%s %s %s %s", DB_HSN_Code, DB_Prod_desc, DB_Quantity, DB_Mrp) != EOF)
  {
    if (strcmp(Input_HSN, DB_HSN_Code) == 0)
    {
      printf("\n Item found with HSN_CODE : %s \n", Input_HSN);
      printf("Enter New Quantity: ");
      scanf(" %d", &new_quantity);
      printf("Enter New MRP: ");
      scanf(" %f", &new_mrp);

      fprintf(tempFile, "%s %s %d %f \n", DB_HSN_Code, DB_Prod_desc, new_quantity, new_mrp);
    }
    else
    {
      fprintf(tempFile, "%s %s %s %s \n", DB_HSN_Code, DB_Prod_desc, DB_Mrp, DB_Quantity);
    }
  }

  fclose(fptr);
  fclose(tempFile);

  remove("Data");
  rename("temp.txt", "Data");
}

