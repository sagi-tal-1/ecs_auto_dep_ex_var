package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
    "fmt"
)

func TestVPC(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "name":                    "test-vpc",
            "name_prefix":             "test",
            "cidr_block":              "10.0.0.0/16",
            "azs_count":               2,
            "azs_names":               []string{"us-east-1a", "us-east-1b"},
            "nat_gateway_ids":         []string{"nat-12345"},
            "internet_gateway_id":     "igw-12345",
            "availability_zones":      []string{"us-east-1a", "us-east-1b"},
            "map_public_ip_on_launch": true,
            "existing_vpc_id":         "",
        },
    })

    defer terraform.Destroy(t, terraformOptions)

    t.Log("Starting Terraform Init and Apply")
    terraform.InitAndApply(t, terraformOptions)
    t.Log("Terraform Apply completed")

    t.Run("VPC Creation", func(t *testing.T) {
        vpcID := terraform.Output(t, terraformOptions, "vpc_id")
        t.Logf("VPC ID: %s", vpcID)
        assert.NotEmpty(t, vpcID, "VPC ID should not be empty")
    })

    t.Run("VPC CIDR", func(t *testing.T) {
        vpcCIDR := terraform.Output(t, terraformOptions, "vpc_cidr_block")
        t.Logf("VPC CIDR: %s", vpcCIDR)
        assert.Equal(t, "10.0.0.0/16", vpcCIDR, "VPC CIDR should match input")
    })

    t.Run("Subnet Creation", func(t *testing.T) {
        publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
        privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
        t.Logf("Public Subnet IDs: %v", publicSubnetIDs)
        t.Logf("Private Subnet IDs: %v", privateSubnetIDs)
        assert.Len(t, publicSubnetIDs, 2, "Should have 2 public subnets")
        assert.Len(t, privateSubnetIDs, 2, "Should have 2 private subnets")
    })

    t.Run("Route Tables", func(t *testing.T) {
        privateRouteTableIDs := terraform.OutputList(t, terraformOptions, "private_route_table_ids")
        publicRouteTableID := terraform.Output(t, terraformOptions, "public_route_table_id")
        t.Logf("Private Route Table IDs: %v", privateRouteTableIDs)
        t.Logf("Public Route Table ID: %s", publicRouteTableID)
        assert.Len(t, privateRouteTableIDs, 2, "Should have 2 private route tables")
        assert.NotEmpty(t, publicRouteTableID, "Public route table ID should not be empty")
    })

    t.Run("Public IP Mapping", func(t *testing.T) {
        publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
        for _, subnetID := range publicSubnetIDs {
            mapPublicIP := terraform.Output(t, terraformOptions, fmt.Sprintf("subnet_%s_map_public_ip_on_launch", subnetID))
            t.Logf("Subnet %s map_public_ip_on_launch: %s", subnetID, mapPublicIP)
            assert.Equal(t, "true", mapPublicIP, fmt.Sprintf("Public subnet %s should have map_public_ip_on_launch set to true", subnetID))
        }
    })
}

