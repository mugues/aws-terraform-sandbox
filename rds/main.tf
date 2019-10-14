resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = "${aws_rds_cluster.default.id}"
  instance_class     = "db.r3.large"
}

resource "aws_rds_cluster" "default" {
  cluster_identifier = "aurora-cluster-demo"
  availability_zones = ["eu-west-1a", "eu-west-1b"]
  database_name      = "mydb"
  master_username    = "foo"
  master_password    = "barbut8chars"
  skip_final_snapshot     = true
}