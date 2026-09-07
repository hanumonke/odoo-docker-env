#!/usr/bin/env python3

import argparse
import logging
import sys
import time

import psycopg2

_logger = logging.getLogger(__name__)

if __name__ == "__main__":
    logging.basicConfig(
        format="%(asctime)s | %(levelname)s | %(message)s",
        level=logging.INFO,
    )

    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", required=True)
    parser.add_argument("--db_port", required=True)
    parser.add_argument("--db_user", required=True)
    parser.add_argument("--db_password", required=True)
    parser.add_argument("--timeout", type=int, default=5)

    args = parser.parse_args()

    timer = time.time()
    while (time.time() - timer) < args.timeout:
        try:
            conn = psycopg2.connect(
                "dbname='postgres' user='%s' host='%s' port='%s' password='%s'"
                % (args.db_user, args.db_host, args.db_port, args.db_password)
            )
            conn.close()
            _logger.info("Connected to postgresql server!")
            sys.exit(0)
        except psycopg2.OperationalError:
            _logger.info(
                "Connection to postgresql server is not yet available, retrying in %s"
                % args.timeout
            )
            time.sleep(1)

    _logger.error(
        "Could not connect to postgresql server within %s seconds" % args.timeout
    )
    sys.exit(1)