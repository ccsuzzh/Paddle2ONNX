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
#include <string>
#include <vector>

#include "paddle2onnx/mapper/mapper.h"

namespace paddle2onnx {

class MatmulMapper : public Mapper {
 public:
  MatmulMapper(const PaddleParser& p, OnnxHelper* helper, int64_t block_id,
               int64_t op_id)
      : Mapper(p, helper, block_id, op_id) {
    GetAttr("transpose_X", &transpose_X_);
    GetAttr("transpose_Y", &transpose_Y_);
    GetAttr("alpha", &alpha_);
  }

  void Opset7() override;

 private:
  std::string GetTrans(std::vector<TensorInfo>& input_info);
  const std::unordered_set<int32_t> kNoNeedCastTypesOpSet7{P2ODataType::FP16, P2ODataType::FP32, P2ODataType::INT32, P2ODataType::INT64};
  bool transpose_X_ = false;
  bool transpose_Y_ = false;
  float alpha_ = 1.0;
};

}  // namespace paddle2onnx
