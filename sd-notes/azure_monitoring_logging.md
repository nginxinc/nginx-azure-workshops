# Setup Steps

## Enable Access and Error logs for N4A

1. To enable logging you need to first create a `Log Analytics Workspace` resource which would be storing all the logs.

### Create Log Analytics Workspace



2. Logging makes use of Kusto Query Language (KQL)
   [https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/tutorials/learn-common-operators]

3. Sample KQL to print all access and error logs

    ```Kusto
    NGXOperationLogs
    | where FilePath == "/var/log/nginx/access.log" or FilePath == "/var/log/nginx/error.log"
    | sort by TimeGenerated asc
    | take 100
    | project  TimeGenerated, FilePath, Message
    ```

4. Access logs donot show up instantly in the logs tool (Takes atleast 3 minutes to show up). Real time analysis is not possible due to this.

5. 