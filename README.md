As part of OpenAPI Specification, extensions allow describing extra properties that start with `x-`, such as `x-billing`. You can define custom specifications in your `API` or `Product` definitions to support your use-cases. 

For instance,

```yaml
plans:
  gold-plan:
    x-billing: # custom properties
      monthly-amount: 10
      one-time-fee: 500
      currancy: SEK
    rate-limits:
      default:
        value: 500/1second
    title: Gold Plan
    approval: false

```

In the following steps, we will extract the extension properties used to define billing information within the `Plan` blocks'. Then, extracting `Subscriptions` objects to calculate charges by consumer organizations.


## Steps

- Update [cred.conf](cred.conf) with the environment details
- Make the `apic` & `script.sh` files executable files by entering the following command:
  ```
  chmod +x apic installer.sh
  ```
- Add `apic` in your **PATH**
  - For the OSX and Linux operating systems:
  ```
  export PATH=$PATH:/Users/your_path/
  ```
  - For the Windows operating system:
  ```
  set PATH=c:\your_path;%PATH%
  ```
- Run `./script.sh`


The script will create a `charges.yaml` file with the following schema:

```yaml
consumer-org-name: 
  app: string
  product-ame: string
  plan: string
  status: string
  billing:
    monthly-amount: number
    one-time-fee: number
    currency: string
    total-amount: number
```

> You may update the script based in the custom properties you add in products definitions.