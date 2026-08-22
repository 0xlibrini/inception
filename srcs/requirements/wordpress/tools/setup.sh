#!/bin/bash

while ! mysqladmin ping -h mariadb --silent; do
    sleep 1
done

