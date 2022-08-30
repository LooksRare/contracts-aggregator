interface AbiArg {
  internalType: string;
  name: string;
  type: string;
}

interface AbiComponent {
  components: AbiArg[];
  internalType: string;
  name: string;
  type: string;
}

export interface AbiFunction {
  inputs: AbiComponent[];
  name: string;
  outputs: AbiArg[];
  stateMutability: string;
  type: string;
}
