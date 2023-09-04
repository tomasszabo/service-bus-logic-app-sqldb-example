# Logic app communicating with ServiceBus and SQL Database using Private Endpoints example

This repository contains example of Logic App communicating with Service Bus and Azure SQL Database. Service Bus and SQL Database are available via Private Endpoints and Logic App is integrated into VNET.

# Architecture

Architecture consist of:

- ServiceBus
- Azure Logic App Workflow to produce messages and write them to ServiceBus queue
- Azure Logic App Workflow to receive messages from ServiceBus queue
- SQL Database to store received messages

# Deployment

To deploy required Azure Resources, go to `bicep` directory and execute following Azure CLI command:

```bash
az deployment group create \
    --resource-group {{resourceGroupName}} \
    --name {{deploymentName}} \
    --template-file main.bicep \
    --parameters sqlPassword={{yourPassword}}
```

After Azure resources were provisioned, both Azure Logic App Workflows needs to be deployed for example from [Visual Studio Code](https://learn.microsoft.com/en-us/azure/logic-apps/create-single-tenant-workflows-visual-studio-code#deploy-to-azure).

Last step is to create table Messages in SQL Database. Sign into SQL Database with your tool of choice and run following SQL statement:

```sql
CREATE TABLE Messages(
	Id int IDENTITY (1, 1) NOT NULL,
	Content varchar(1024)
)
```

# Generate Message

After successful deployment go to `Azure Portal > logicapp > Workflows > GenerateMessage workflow` and copy `Workflow Url` to clipboard. Create POST request to copied URL with HTTP body:

```json
{
	"message": "your message"
}
```

After successful execution, message is sent to ServiceBus queue.

# Receive Message

After message was generated, second Azure Logic App Workflow is listening for messages in ServiceBus queue. After a message was received, it is inserted as a new record into SQL Database.

# License

Distributed under MIT License. See [LICENSE](LICENSE) for more details.