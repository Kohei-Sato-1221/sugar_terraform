# sugar_terraform
Terraform用のプロジェクト


# リソースの計画
```
terraform plan -var 'env=prod'
terraform plan -var 'env=dev'
```

# リソースの作成
```
terraform apply -var 'env=prod'
terraform apply -var 'env=dev'
```

# リソースの削除
```
terraform destroy
```