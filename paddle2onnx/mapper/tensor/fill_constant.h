// Copyright (c) 2022 PaddlePaddle Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#pragma once
#include "paddle2onnx/mapper/mapper.h"

namespace paddle2onnx {

class FillConstantMapper : public Mapper {
 public:
  FillConstantMapper(const PaddleParser& p, OnnxHelper* helper,
                     int64_t block_id, int64_t op_id)
      : Mapper(p, helper, block_id, op_id) {
    GetAttr("str_value", &str_value_);
    GetAttr("value", &value_);
  }

  int32_t GetMinOpsetVersion(bool verbose) override;
  void Opset7() override;
  void Opset9() override;

 private:
  float GetFillValue();
  std::string str_value_;
  float value_;
};

}  // namespace paddle2onnx
