#!/bin/bash

echo "<FIXME:icname>: "
gcloud compute interconnects attachments describe <FIXME:icname> --region <FIXME:region> | grep pairingKey
echo "<FIXME:icname>: "
gcloud compute interconnects attachments describe <FIXME:icname> --region <FIXME:region> | grep pairingKey