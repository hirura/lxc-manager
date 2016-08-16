#!/bin/bash

_dir=$(dirname $0)
(cd $_dir/.. && bundle exec rake db:drop)
(cd $_dir/.. && bundle exec rake db:migrate)
